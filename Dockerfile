ARG BASE_IMAGE_PREFIX

FROM multiarch/qemu-user-static as qemu

FROM ${BASE_IMAGE_PREFIX}tomcat:9-jre11

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin/

# To update, check http://guac-dev.org/releases
ENV GUACAMOLE_VERSION           1.2.0
ENV GUACAMOLE_HOME              /app/guacamole

### Guacamole webapp
# Disable Tomcat's manager application.
RUN rm -rf webapps/*

# Expose tomcat runtime options through the RUNTIME_OPTS environment variable.
#   Example to set the JVM's max heap size to 256MB use the flag
#   '-e RUNTIME_OPTS="-Xmx256m"' when starting a container.
RUN echo 'export CATALINA_OPTS="$RUNTIME_OPTS"' > bin/setenv.sh

### Guacamole jdbc auth extension
# Fetch and install Guacamole jdbc auth extension libs
RUN mkdir -p ${GUACAMOLE_HOME} \
         ${GUACAMOLE_HOME}/lib \
         ${GUACAMOLE_HOME}/extensions;

WORKDIR ${GUACAMOLE_HOME}

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" \
  && curl -SLo mysql-connector.tar.gz "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.22.tar.gz" \
  && tar xzf mysql-connector.tar.gz \
  && mv mysql-connector-java-*/mysql-connector-java-*.jar ${GUACAMOLE_HOME}/lib \
  && rm -rf mysql-connector* \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUACAMOLE_VERSION} guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz

# Add optional extensions
RUN set -xe \
  && mkdir ${GUACAMOLE_HOME}/extensions-available \
  && for i in auth-ldap auth-duo auth-header auth-cas auth-openid auth-quickconnect auth-totp; do \
    echo "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${i}-${GUACAMOLE_VERSION}.tar.gz" \
    && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${i}-${GUACAMOLE_VERSION}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUACAMOLE_VERSION}.tar.gz \
    && cp guacamole-${i}-${GUACAMOLE_VERSION}/guacamole-${i}-${GUACAMOLE_VERSION}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUACAMOLE_VERSION} guacamole-${i}-${GUACAMOLE_VERSION}.tar.gz \
  ;done

### Configuration
ENV GUACAMOLE_HOME=/data/guacamole

WORKDIR /data

COPY rootfs /

RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /usr/bin/qemu-*-static
