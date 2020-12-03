#!/bin/sh

SHIPA_CLIENT="/bin/shipa"

if [ "x$DASHBOARD_ENABLED" != "xtrue" ]; then
  echo "The dashboard is disabled"
  exit 0
fi

$SHIPA_CLIENT app-info -a dashboard > /dev/null 2>&1

if [ $? = 1 ]; then
  echo "Creating the dashboard app"
  $SHIPA_CLIENT app-create dashboard static \
      --pool=theonepool \
      --team=shipa-team \
      -e SHIPA_ADMIN_USER=$USERNAME
fi

NETDATA_CLIENT_CERT=$(kubectl get secret/shipa-certificates -o json | jq ".data[\"netdata-client.crt\"]" | base64 -d)
NETDATA_CLIENT_KEY=$(kubectl get secret/shipa-certificates -o json | jq ".data[\"netdata-client.key\"]" | base64 -d)

$SHIPA_CLIENT env-set -a dashboard NETDATA_CLIENT_KEY="$NETDATA_CLIENT_KEY" NETDATA_CLIENT_CERT="$NETDATA_CLIENT_CERT"

EVENT_ID=$($SHIPA_CLIENT event-list --target=app --target-value=dashboard --kind=app.deploy | grep true | head -n 1 | cut -d "|" -f 2)

if [ "x$EVENT_ID" != "x" ]; then
  echo "Found app.deploy event for the dashboard: $EVENT_ID"
  echo "Checking image used to deploy the dashboard"
  SAME_IMAGE=$($SHIPA_CLIENT event-info $EVENT_ID | grep -e "$DASHBOARD_IMAGE$")

  if [ "x$SAME_IMAGE" != "x" ]; then
    echo "The dashboard uses the same image : $DASHBOARD_IMAGE"

    # That's helm upgrade, we should wait for a new shipa api
    sleep 140

    #
    # Let's restart the dashboard, there is a chance that a user has changed a license (Free -> Pro)
    #
    $SHIPA_CLIENT app-restart -a dashboard
    exit 0
  fi
fi

$SHIPA_CLIENT app-deploy -a dashboard -i $DASHBOARD_IMAGE
