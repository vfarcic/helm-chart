#!/bin/sh

echo "Waiting for shipa api"

until $(curl --output /dev/null --silent http://$SHIPA_ENDPOINT); do
    echo "."
    sleep 2
done

SHIPA_CLIENT="/bin/shipa"
$SHIPA_CLIENT target-add local http://$SHIPA_ENDPOINT
$SHIPA_CLIENT target-set local
$SHIPA_CLIENT login << EOF
$USERNAME
$PASSWORD
EOF
$SHIPA_CLIENT team-create admin
$SHIPA_CLIENT team-create system
$SHIPA_CLIENT pool-add theonepool --public -d --provisioner=kubernetes

TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
ADDR=$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT

$SHIPA_CLIENT cluster-add theonepool kubernetes --pool=theonepool \
  --cacert=$CACERT \
  --addr=$ADDR \
  --custom="token=$TOKEN" \
  --custom="namespace=$POD_NAMESPACE"
$SHIPA_CLIENT role-add NodeContainer pool
$SHIPA_CLIENT role-add ShipaUser global
$SHIPA_CLIENT role-permission-add ShipaUser pool.create
$SHIPA_CLIENT role-permission-add ShipaUser team.create
$SHIPA_CLIENT role-add TeamAdmin team
$SHIPA_CLIENT role-permission-add TeamAdmin team
$SHIPA_CLIENT role-permission-add TeamAdmin app
$SHIPA_CLIENT role-add PoolAdmin pool
$SHIPA_CLIENT role-permission-add PoolAdmin pool
$SHIPA_CLIENT role-permission-add PoolAdmin node
$SHIPA_CLIENT role-default-add --team-create TeamAdmin
$SHIPA_CLIENT role-default-add --pool-add PoolAdmin
$SHIPA_CLIENT role-default-add --user-create ShipaUser
$SHIPA_CLIENT role-permission-add NodeContainer app.metrics.write
$SHIPA_CLIENT role-permission-add NodeContainer app.update.log
$SHIPA_CLIENT role-permission-add NodeContainer pool.metrics.write
$SHIPA_CLIENT role-permission-add NodeContainer node.update.status
$SHIPA_CLIENT token-create --team=system --id=system-node-container
$SHIPA_CLIENT role-assign NodeContainer system-node-container theonepool
$SHIPA_CLIENT role-add PlatformImageAdmin global
$SHIPA_CLIENT role-add PlatformImageReader global
$SHIPA_CLIENT role-add AppImageAdmin app
$SHIPA_CLIENT role-add AppImageReader app
$SHIPA_CLIENT role-permission-add  PlatformImageAdmin platform.image.read
$SHIPA_CLIENT role-permission-add  PlatformImageAdmin platform.image.write
$SHIPA_CLIENT role-permission-add  PlatformImageReader platform.image.read
$SHIPA_CLIENT role-permission-add  AppImageReader app.read.image
$SHIPA_CLIENT role-permission-add  AppImageAdmin app.read.image
$SHIPA_CLIENT role-permission-add  AppImageAdmin app.update.image

$SHIPA_CLIENT node-container-add netdata \
        --enable=true \
        --privileged=true \
        --image=shipasoftware/netdata:latest -p 19999:19999 \
        -v /etc/passwd:/host/etc/passwd:ro \
        -v /etc/group:/host/etc/group:ro \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro

$SHIPA_CLIENT node-container-upgrade netdata -y --pool=theonepool

$SHIPA_CLIENT platform-add python

$SHIPA_CLIENT app-create dashboard python \
    --pool=theonepool \
    --team=admin \
    -e METRICS_HOST=http://$METRICS_SERVICE:9090 \
    -e METRICS_PASSWORD="$METRICS_PASSWORD" \
    -e TRAEFIK_DASHBOARD_PASSWORD="" \
    -e TRAEFIK_DASHBOARD_HOST=http://$TRAEFIK_INTERNAL_SERVICE:9095

$SHIPA_CLIENT app-deploy -a dashboard -i $DASHBOARD_IMAGE

