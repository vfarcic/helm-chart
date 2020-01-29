#!/bin/sh

. /init/common.sh

set_public_ips

echo "Prepare shipa.conf"
cp -v /etc/shipa-default/shipa.conf /etc/shipa/shipa.conf
sed -i "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /etc/shipa/shipa.conf
sed -i "s/TRAEFIK_IP/$TRAEFIK_ADDRESS/g" /etc/shipa/shipa.conf

echo "shipa.conf: "
cat /etc/shipa/shipa.conf

if is_shipa_initialized; then
  echo "Skip bootstrapping because shipa is already initialized"
  exit 0
fi

. /init/gencerts.sh
