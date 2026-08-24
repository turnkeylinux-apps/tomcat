#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
db_password=${TKL_TEST_DB_PASS:?TKL_TEST_DB_PASS is required}
manager=http://127.0.0.1/manager/text
context=/turnkey-v19-test
war_root=$(mktemp -d /tmp/tkl-tomcat-war.XXXXXX)
war=/tmp/tkl-tomcat-v19.$$.war
response=/tmp/tkl-tomcat-response.$$
policy=/tmp/tkl-tomcat-policy.$$
database=tkl_tomcat_v19_acceptance
deployed=false
database_created=false

cleanup() {
    if $deployed; then
        curl --fail --silent --show-error --user "admin:$password" \
            "$manager/undeploy?path=$context" >/dev/null || true
    fi
    if $database_created; then
        mariadb --user=root --password="$db_password" \
            --execute "DROP DATABASE IF EXISTS $database" || true
    fi
    rm -rf -- "$war_root"
    rm -f -- "$war" "$response" "$policy"
}
trap cleanup EXIT

systemctl --quiet is-active tomcat10.service mariadb.service multi-user.target
systemctl --quiet is-enabled tomcat10.service mariadb.service

tomcat_package=$(dpkg-query -W -f='${Version}' tomcat10)
tomcat_admin_package=$(dpkg-query -W -f='${Version}' tomcat10-admin)
java_package=$(dpkg-query -W -f='${Version}' openjdk-21-jre-headless)
mariadb_package=$(dpkg-query -W -f='${Version}' mariadb-server)
java_version=$(java -version 2>&1 | head -n 1)
tomcat_version=$(/usr/share/tomcat10/bin/version.sh 2>&1 | \
    awk -F': ' '/Server number/ {print $2}')

grep -q '^10\.1\.' <<<"$tomcat_version"
grep -q 'version "21\.' <<<"$java_version"
java_binary=$(readlink -f "$(command -v java)")
dpkg-query -S /usr/share/tomcat10/bin/catalina.sh "$java_binary" >/dev/null
test -d /usr/share/tomcat10-admin/manager
test -d /usr/share/tomcat10-admin/host-manager
test -d /usr/share/tomcat10-docs/docs
test -s /etc/tomcat10/cert.p12
grep -q 'CATALINA_HOME="/usr/share/tomcat10"' /etc/environment
grep -q 'JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"' /etc/environment
! ss -ltnH 'sport = :8009' | grep -q .

curl --retry 15 --retry-all-errors --retry-delay 1 \
    --fail --silent --show-error http://127.0.0.1/ >"$response"
grep -q 'TurnKey Tomcat' "$response"
grep -q 'href="/manager/html"' "$response"
grep -q 'href="/host-manager/html"' "$response"
grep -q 'https://127.0.0.1:12321' "$response"
curl --insecure --fail --silent --show-error \
    https://127.0.0.1/ >"$response"
grep -q 'TurnKey Tomcat' "$response"

test "$(curl --silent --output /dev/null --write-out '%{http_code}' \
    http://127.0.0.1/manager/html)" = 401
curl --fail --silent --show-error --user "admin:$password" \
    http://127.0.0.1/manager/html >"$response"
grep -q 'Tomcat Web Application Manager' "$response"
curl --fail --silent --show-error --user "admin:$password" \
    http://127.0.0.1/host-manager/html >"$response"
grep -q 'Tomcat Virtual Host Manager' "$response"
curl --fail --silent --show-error --user "admin:$password" \
    "$manager/serverinfo" >"$response"
grep -Fxq 'OK - Server info' "$response"
grep -q '^Tomcat Version: \[Apache Tomcat/10\.1\.' "$response"
grep -q 'username="admin"' /etc/tomcat10/tomcat-users.xml
! grep -q 'password="turnkey"' /etc/tomcat10/tomcat-users.xml

cat >"$war_root/index.jsp" <<'EOF'
<%@ page contentType="text/plain" %>turnkey-tomcat-v19-deploy-ok
EOF
jar --create --file "$war" -C "$war_root" .
curl --fail --silent --show-error --user "admin:$password" \
    --upload-file "$war" \
    "$manager/deploy?path=$context&update=true" >"$response"
grep -q '^OK - Deployed application at context path' "$response"
deployed=true
curl --retry 5 --retry-delay 1 --fail --silent --show-error \
    "http://127.0.0.1$context/" >"$response"
grep -Fxq 'turnkey-tomcat-v19-deploy-ok' "$response"
curl --insecure --fail --silent --show-error \
    "https://127.0.0.1$context/" >"$response"
grep -Fxq 'turnkey-tomcat-v19-deploy-ok' "$response"
curl --fail --silent --show-error --user "admin:$password" \
    "$manager/undeploy?path=$context" >"$response"
grep -q '^OK - Undeployed application at context path' "$response"
deployed=false
test "$(curl --silent --output /dev/null --write-out '%{http_code}' \
    "http://127.0.0.1$context/")" = 404

dpkg-query -W webmin-mysql >/dev/null
curl --insecure --fail --silent --show-error --head \
    https://127.0.0.1:12321/ >/dev/null

mariadb --user=root --password="$db_password" \
    --execute "CREATE DATABASE $database"
database_created=true
mariadb --user=root --password="$db_password" "$database" --execute \
    'CREATE TABLE probe (value VARCHAR(32)); INSERT INTO probe VALUES ("database-ok")'
mariadb --user=root --password="$db_password" --batch --skip-column-names \
    "$database" \
    --execute 'SELECT value FROM probe' | grep -Fxq 'database-ok'
mariadb --user=root --password="$db_password" "$database" \
    --execute 'DELETE FROM probe; DROP TABLE probe'
mariadb --user=root --password="$db_password" \
    --execute "DROP DATABASE $database"
database_created=false

before="$tomcat_package|$tomcat_admin_package|$java_package|$mariadb_package"
apt-get update >/dev/null
for package in tomcat10 tomcat10-admin openjdk-21-jre-headless mariadb-server; do
    apt-cache policy "$package" >"$policy"
    candidate=$(awk '/Candidate:/ {print $2}' "$policy")
    test -n "$candidate"
    test "$candidate" != '(none)'
    grep -Eq 'trixie|deb13' "$policy"
done
after="$(dpkg-query -W -f='${Version}' tomcat10)|$(dpkg-query -W -f='${Version}' tomcat10-admin)|$(dpkg-query -W -f='${Version}' openjdk-21-jre-headless)|$(dpkg-query -W -f='${Version}' mariadb-server)"
test "$after" = "$before"
grep -Rqs '^Suites: trixie' /etc/apt/sources.list.d
! grep -Rqi bookworm /etc/apt/sources.list.d

cat >"$result" <<EOF
package_source=Debian 13 Trixie APT repositories for Tomcat 10.1, OpenJDK 21 and MariaDB; TurnKey APT for Webmin
installed_version=tomcat10 $tomcat_package (Tomcat $tomcat_version); tomcat10-admin $tomcat_admin_package; openjdk-21-jre-headless $java_package ($java_version); mariadb-server $mariadb_package
runtime_checks=normal init; Tomcat and MariaDB services; direct HTTP and HTTPS landing page; unauthenticated manager denial; authenticated manager and host manager; WAR deploy, HTTP and HTTPS readback, and undeploy; MariaDB roundtrip; Webmin endpoint
updater_command=apt-get update; apt-cache policy tomcat10 tomcat10-admin openjdk-21-jre-headless mariadb-server
updater_result=signed metadata refreshed; eligible Trixie candidates found; installed versions unchanged
updater_channel=Debian Trixie and TurnKey Trixie APT repositories
integrity_evidence=APT accepted signed repository metadata through configured Deb822 sources and keyrings; no Bookworm source remained
EOF
