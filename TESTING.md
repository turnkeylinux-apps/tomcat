# Tomcat 19.0 acceptance

## Source decision

Tomcat 19.0 uses Debian 13 Trixie packages for Tomcat 10.1, its manager
applications, OpenJDK 21 and MariaDB. Webmin and its MariaDB module continue to
come from the signed TurnKey Trixie repository. The complete documented stack
is maintained through APT, so this appliance does not need an upstream package
source or a separate updater.

The standalone appliance binds Tomcat directly to ports 80 and 443. It does
not use the Apache reverse proxy provided by the separate Tomcat on Apache
appliance.

The shared v19 cipher substitution leaves its quoted placeholder attached to
the selected Tomcat cipher list. The appliance removes only that invalid XML
suffix after shared configuration, preserving the shared Trixie cipher
selection.

## Acceptance command

```sh
/sandboxed-git/turnkey/tools/test-v19-appliance tomcat \
    --source /home/agent/.local/worktrees/turnkey-apps/tomcat/wish-tomcat-v19-trixie
```

## README crosswalk

| README contract | Focused check | Required result |
| --- | --- | --- |
| Tomcat 10.1 and OpenJDK 21 come from Debian | Query packages, versions and binary ownership | Versions match Trixie packages |
| Standalone HTTP and HTTPS on ports 80 and 443 | Request the landing page through both connectors | Both responses identify TurnKey Tomcat |
| Manager and Virtual Host Manager use the firstboot admin account | Check unauthenticated denial, then authenticate to both applications and the text manager | Anonymous access is denied and the generated password succeeds |
| Applications deploy under `/var/lib/tomcat10/webapps` | Upload a minimal JSP WAR through the manager, request it through HTTP and HTTPS, then undeploy it | Deployment, both readbacks and removal succeed |
| AJP on port 8009 is disabled | Inspect runtime listeners | No listener exists on port 8009 |
| MariaDB is available for applications | Create a temporary database and table, write and read a row, then remove them | The database roundtrip succeeds |
| Webmin is the documented system management surface | Request its HTTPS endpoint and verify the MariaDB module package | Webmin responds and the module is installed |
| APT maintains the packaged stack | Refresh metadata and inspect candidates for identity-defining packages | Signed Trixie metadata is accepted, candidates exist and installed versions remain unchanged |
| Root Webmin and SSH credentials are inherited from Core | Cite the unchanged Core layer | Core 19 passed at source `24c82ee3540ce545422742b0e28ba6b687c53ec2` |

## Updater check

`tests/v19.sh` runs `apt-get update` and checks candidates for `tomcat10`,
`tomcat10-admin`, `openjdk-21-jre-headless` and `mariadb-server`. It confirms
that the refresh does not change installed versions and that no Bookworm
source remains.

## Core evidence and limitations

Core 19 run `20260824t010251z-1634-32241` passed normal init, multi-user, SSH,
cron, Trixie identity and the signed APT updater at source
`24c82ee3540ce545422742b0e28ba6b687c53ec2`.

Docker acceptance does not exercise the installer, kernel, bootloader or
physical hardware. Tomcat adds no behavior at those boundaries, so the Core
19 result supplies the inherited evidence.

## Accepted run

Pending the exact acceptance command above.

## Deferred minor issues

- The package plan still includes `authbind` and its historical port files.
  Trixie's Tomcat systemd unit grants only the low-port capability needed for
  ports 80 and 443, so Tomcat no longer relies on authbind. The compatibility
  files are harmless and remain for v19.0.
