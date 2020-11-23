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

ARG DOCKER_IMAGE_ARCH

# Apply the s6-overlay
RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v1.20.0.0/s6-overlay-${DOCKER_IMAGE_ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${DOCKER_IMAGE_ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${DOCKER_IMAGE_ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${DOCKER_IMAGE_ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
      ${GUACAMOLE_HOME}/lib \
      ${GUACAMOLE_HOME}/extensions \
      ${GUACAMOLE_HOME}/mysql \
      ${GUACAMOLE_HOME}/postgresql;

WORKDIR ${GUACAMOLE_HOME}

### Guacamole jdbc auth extension
# Fetch and install Guacamole jdbc auth extension libs

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.1.4.jar "https://jdbc.postgresql.org/download/postgresql-42.1.4.jar" \
  && curl -SLo mysql-connector.tar.gz "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.22.tar.gz" \
  && tar xzf mysql-connector.tar.gz \
  && mv mysql-connector-java-*/mysql-connector-java-*.jar ${GUACAMOLE_HOME}/lib \
  && rm -rf mysql-connector* \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/schema ${GUACAMOLE_HOME}/mysql/ \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/postgresql/guacamole-auth-jdbc-postgresql-${GUACAMOLE_VERSION}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUACAMOLE_VERSION}/postgresql/schema ${GUACAMOLE_HOME}/postgresql/ \
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

WORKDIR /config

COPY rootfs /

RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /usr/bin/qemu-*-static

ENTRYPOINT [ "/init" ]
