#!/usr/bin/with-contenv sh

cp -rn /app/guacamole /data/guacamole
mkdir -p /config/guacamole
cp -rn /config/guacamole /data/guacamole
mkdir -p /root/.data/freerdp/known_hosts
