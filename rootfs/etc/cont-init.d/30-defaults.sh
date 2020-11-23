#!/usr/bin/with-contenv sh

cp -rn /app/guacamole /data
mkdir -p /config/guacamole
cp -rn /config/guacamole /data
mkdir -p /root/.data/freerdp/known_hosts
