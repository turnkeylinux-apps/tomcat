Standalone Tomcat - Java Servlet and JSP Platform
=================================================

`Tomcat`_ is a servlet container that implements the Java Servlet and
the JavaServer Pages (JSP) specifications, and provides a "pure Java"
HTTP web server environment for Java code to run in. Tomcat powers
numerous large-scale, mission-critical web applications across a diverse
range of industries and organizations.

This appliance configures Tomcat as a standalone application server
(that is, without an external web server). A `Tomcat on Apache Appliance`_
is also available for integrations requiring a fully-featured web
server.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Tomcat configurations:
   
   - Tomcat 10.1 installed from Debian package management.
   - Using the OpenJDK 21 Java runtime from Debian.
   - Web applications in /var/lib/tomcat10/webapps.
   - Includes TurnKey web control panel.
   - Created Tomcat admin/manager roles and admin user.
   - Tomcat Manager at /manager/html and Virtual Host Manager at
     /host-manager/html.
   - Binds the Tomcat HTTP connector directly to port 80 (default: 8080).
   - Binds the Tomcat SSL interface directly to port 443 (default: 8443).
   - Disabled AJP connector on port 8009 (security).
   - Tomcat and Java environment variables configuration system wide.

- Includes MariaDB, a MySQL-compatible database server.
- SSL support out of the box.
- Postfix MTA (bound to localhost) to allow sending of email from web
  applications (e.g., password recovery).

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MariaDB: username **root**
-  Tomcat administration applications: username **admin**


.. _Tomcat: https://tomcat.apache.org
.. _Tomcat on Apache Appliance: https://www.turnkeylinux.org/tomcat-apache
.. _TurnKey Core: https://www.turnkeylinux.org/core
