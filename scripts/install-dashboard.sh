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
    -e SHIPA_ADMIN_USER=$USERNAME \
    -e SHIPA_CLOUD=$SHIPA_CLOUD \
    -e SANDBOX_DURATION_HOURS=$SANDBOX_DURATION_HOURS
    -e SANDBOX_TRAIL_HOURS=$SANDBOX_TRIAL_HOURS
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