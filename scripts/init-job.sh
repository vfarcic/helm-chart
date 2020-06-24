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
$SHIPA_CLIENT pool-add /scripts/default-pool-template.yaml

TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
ADDR=$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT

sleep 10
$SHIPA_CLIENT cluster-add theonepool --pool=theonepool \
  --cacert=$CACERT \
  --addr=$ADDR \
  --ingress-service-type=ClusterIP \
  --token=$TOKEN

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

$SHIPA_CLIENT role-add NodeContainer pool
$SHIPA_CLIENT role-permission-add NodeContainer metrics.write
$SHIPA_CLIENT role-permission-add NodeContainer app.update.log
$SHIPA_CLIENT role-permission-add NodeContainer node.update.status

$SHIPA_CLIENT role-add ClusterNodeContainer cluster
$SHIPA_CLIENT role-permission-add ClusterNodeContainer metrics.write
$SHIPA_CLIENT role-permission-add ClusterNodeContainer app.update.log
$SHIPA_CLIENT role-permission-add ClusterNodeContainer node.update.status

$SHIPA_CLIENT role-add ClusterMetricsWriter cluster
$SHIPA_CLIENT role-permission-add ClusterMetricsWriter metrics.write

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
        --image=$NETDATA_IMAGE -p 19999:19999 \
        -v /etc/passwd:/host/etc/passwd:ro \
        -v /etc/group:/host/etc/group:ro \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro

$SHIPA_CLIENT node-container-upgrade netdata -y --pool=theonepool

platforms=$(echo $PLATFORMS | tr " " "\n")

echo "waiting busybody daemons..."
sleep 30

for platform in $platforms;
do
   $SHIPA_CLIENT platform-add $platform
done

/scripts/install-dashboard.sh
