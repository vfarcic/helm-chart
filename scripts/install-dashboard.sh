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
      --team=admin \
      -e SHIPA_ADMIN_USER=$USERNAME
fi

EVENT_ID=$($SHIPA_CLIENT event-list --target=app --target-value=dashboard --kind=app.deploy | grep true | head -n 1 | cut -d "|" -f 2)

if [ "x$EVENT_ID" != "x" ]; then
  echo "Found app.deploy event for the dashboard: $EVENT_ID"
  echo "Checking image used to deploy the dashboard"
  SAME_IMAGE=$($SHIPA_CLIENT event-info $EVENT_ID | grep -e "$DASHBOARD_IMAGE$")

  if [ "x$SAME_IMAGE" != "x" ]; then
    echo "The dashboard uses the same image : $DASHBOARD_IMAGE"

    #
    # Let's restart the dashboard, there is a chance that a user has changed a license (Free -> Pro)
    #
    $SHIPA_CLIENT app-restart -a dashboard
    exit 0
  fi
fi

$SHIPA_CLIENT app-deploy -a dashboard -i $DASHBOARD_IMAGE
