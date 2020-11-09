ARG BASE_IMAGE_PREFIX

FROM multiarch/qemu-user-static as qemu

FROM ${BASE_IMAGE_PREFIX}tomcat:9-jre11

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin/

# To update, check http://guac-dev.org/releases
ENV GUACAMOLE_VERSION         1.2.0
ENV GUACAMOLE_WAR_SHA256        4c95e0241df1143f216ccccd0e33e1d7d10ac6c1c13f81c281bc5bc0144a0b04
ENV GUACAMOLE_AUTH_MYSQL_SHA1 a68166aec88784325f3358a16dedc70f2df73342
ENV MYSQL_CONNECTOR_MD5       ad4c875c719247f8e8c41cd7f0609e00

### Guacamole webapp
# Disable Tomcat's manager application.
RUN rm -rf webapps/*

# Fetch and install Guacamole war archive.
RUN echo $GUACAMOLE_WAR_SHA256  ROOT.war > webapps/ROOT.war.sha1 && \
    curl -L -o webapps/ROOT.war http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war && \
    cd webapps && sha256sum -c --quiet ROOT.war.sha256

# Expose tomcat runtime options through the RUNTIME_OPTS environment variable.
#   Example to set the JVM's max heap size to 256MB use the flag
#   '-e RUNTIME_OPTS="-Xmx256m"' when starting a container.
RUN echo 'export CATALINA_OPTS="$RUNTIME_OPTS"' > bin/setenv.sh

### Guacamole MySQL auth extension
# Fetch and install Guacamole MySQL auth extension libs
RUN mkdir -p /guacamole/classpath
RUN echo $GUACAMOLE_AUTH_MYSQL_SHA1  guacamole-auth-mysql.tar.gz > guacamole-auth-mysql.tar.gz.sha1 && \
    curl -L -o guacamole-auth-mysql.tar.gz http://sourceforge.net/projects/guacamole/files/current/extensions/guacamole-auth-mysql-0.9.4.tar.gz/download && \
    sha1sum -c --quiet guacamole-auth-mysql.tar.gz.sha1 && \
    tar xzf guacamole-auth-mysql.tar.gz && \
    mv guacamole-auth-mysql-${GUACAMOLE_VERSION}/lib/*.jar /guacamole/classpath && \
    rm -rf guacamole-auth-mysql*

# Fetch and install MySQL connector
RUN echo $MYSQL_CONNECTOR_MD5  mysql-connector.tar.gz > mysql-connector.tar.gz.md5 && \
    curl -L -o mysql-connector.tar.gz http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.34.tar.gz && \
    md5sum -c --quiet mysql-connector.tar.gz.md5 && \
    tar xzf mysql-connector.tar.gz && \
    mv mysql-connector-java-*/mysql-connector-java-*.jar /guacamole/classpath && \
    rm -rf mysql-connector*

RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /usr/bin/qemu-*-static

### Configuration
ENV GUACAMOLE_HOME /guacamole
COPY guacamole.properties ${GUACAMOLE_HOME}/
