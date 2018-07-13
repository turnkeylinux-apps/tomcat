Standalone Tomcat - Java Servlet and JSP Platform
=================================================

`Tomcat`_ is a servlet container that implements the Java Servlet and
the JavaServer Pages (JSP) specifications, and provides a "pure Java"
HTTP web server environment for Java code to run in. Tomcat powers
numerous large-scale, mission-critical web applications across a diverse
range of industries and organizations.

This appliance configures Tomcat as a standalone application server
(I.e., without an external web server). A `Tomcat on Apache Appliance`_
is also available for integrations requiring a fully-featured web
server.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Tomcat configurations:
   
   - Installed from package management.
   - Using OpenJDK Java runtime.
   - Web applications in /var/lib/tomcat8/webapps.
   - Includes TurnKey web control panel.
   - Created Tomcat admin/manager roles and admin user.
   - Bind Tomcat HTTP connector to port 80 (default: 8180).
   - Bind SSL interface to port 443 (default: 8443).
   - Disabled AJP connector on port 8009 (security).
   - Tomcat and Java environment variables configuration system wide.

- Includes MySQL.
- SSL support out of the box.
- Postfix MTA (bound to localhost) to allow sending of email from web
  applications (e.g., password recovery).

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Tomcat administration applications: username **admin**


.. _Tomcat: http://tomcat.apache.org
.. _Tomcat on Apache Appliance: https://www.turnkeylinux.org/tomcat-apache
.. _TurnKey Core: https://www.turnkeylinux.org/core
