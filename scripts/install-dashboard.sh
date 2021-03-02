#!/bin/sh

SHIPA_CLIENT="/bin/shipa"

if [ "x$DASHBOARD_ENABLED" != "xtrue" ]; then
  echo "The dashboard is disabled"
  exit 0
fi

echo "Creating the dashboard app"
$SHIPA_CLIENT app-create dashboard static \
    --framework=shipa-framework \
    --team=shipa-admin-team \
    -e SHIPA_ADMIN_USER=$USERNAME

NETDATA_CLIENT_CERT=$(kubectl get secret/shipa-certificates -o json | jq ".data[\"netdata-client.crt\"]" | base64 -d)
NETDATA_CLIENT_KEY=$(kubectl get secret/shipa-certificates -o json | jq ".data[\"netdata-client.key\"]" | base64 -d)

$SHIPA_CLIENT env-set -a dashboard NETDATA_CLIENT_KEY="$NETDATA_CLIENT_KEY" NETDATA_CLIENT_CERT="$NETDATA_CLIENT_CERT"

COUNTER=0
until $SHIPA_CLIENT app-deploy -a dashboard -i $DASHBOARD_IMAGE
do
    echo "Deploy dashboard failed with $?, waiting 30 seconds then trying again"
    sleep 30
    let COUNTER=COUNTER+1
    if [ $COUNTER -gt 3 ]; then
	echo "Failed to deploy dashboard three times, giving up"
	exit 1
    fi
    
done