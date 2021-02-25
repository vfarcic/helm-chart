#!/bin/sh

echo "Waiting for shipa api"

until $(curl --output /dev/null --silent http://$SHIPA_ENDPOINT:$SHIPA_ENDPOINT_PORT); do
    echo "."
    sleep 2
done

SHIPA_CLIENT="/bin/shipa"
$SHIPA_CLIENT target-add -s local $SHIPA_ENDPOINT --insecure --port=$SHIPA_ENDPOINT_PORT
$SHIPA_CLIENT login << EOF
$USERNAME
$PASSWORD
EOF
$SHIPA_CLIENT team-create shipa-admin-team
$SHIPA_CLIENT team-create shipa-system-team
$SHIPA_CLIENT framework-add /scripts/default-framework-template.yaml

TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
ADDR=$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT

sleep 10
if [[ -z $ISTIO_INGRESS_IP ]]; then
  $SHIPA_CLIENT cluster-add shipa-cluster --framework=shipa-framework \
    --cacert=$CACERT \
    --addr=$ADDR \
    --ingress-service-type="traefik:$INGRESS_SERVICE_TYPE" \
    --ingress-ip="traefik:$INGRESS_IP" \
    --ingress-debug="traefik:$INGRESS_DEBUG" \
    --install-cert-manager=$INSTALL_CERT_MANAGER \
    --token=$TOKEN
else
    $SHIPA_CLIENT cluster-add shipa-cluster --framework=shipa-framework \
    --cacert=$CACERT \
    --addr=$ADDR \
    --ingress-service-type="traefik:$INGRESS_SERVICE_TYPE" \
    --ingress-ip="traefik:$INGRESS_IP" \
    --ingress-debug="traefik:$INGRESS_DEBUG" \
    --ingress-service-type="istio:$ISTIO_INGRESS_SERVICE_TYPE" \
    --ingress-ip="istio:$ISTIO_INGRESS_IP" \
    --install-cert-manager=$INSTALL_CERT_MANAGER \
    --token=$TOKEN
fi

$SHIPA_CLIENT role-add TeamAdmin team
$SHIPA_CLIENT role-permission-add TeamAdmin team
$SHIPA_CLIENT role-permission-add TeamAdmin app
$SHIPA_CLIENT role-permission-add TeamAdmin cluster
$SHIPA_CLIENT role-permission-add TeamAdmin service
$SHIPA_CLIENT role-permission-add TeamAdmin service-instance

$SHIPA_CLIENT role-add FrameworkAdmin framework
$SHIPA_CLIENT role-permission-add FrameworkAdmin framework
$SHIPA_CLIENT role-permission-add FrameworkAdmin node
$SHIPA_CLIENT role-permission-add FrameworkAdmin cluster

$SHIPA_CLIENT role-add ClusterAdmin cluster
$SHIPA_CLIENT role-permission-add ClusterAdmin cluster

$SHIPA_CLIENT role-add ServiceAdmin service
$SHIPA_CLIENT role-add ServiceInstanceAdmin service-instance

$SHIPA_CLIENT role-default-add --team-create TeamAdmin
$SHIPA_CLIENT role-default-add --framework-add FrameworkAdmin
$SHIPA_CLIENT role-default-add --cluster-add ClusterAdmin
$SHIPA_CLIENT role-default-add --service-add ServiceAdmin
$SHIPA_CLIENT role-default-add --service-instance-add ServiceInstanceAdmin

$SHIPA_CLIENT node-container-add netdata \
        --enable=true \
        --privileged=true \
        --image=$NETDATA_IMAGE -p 19999:19999 \
        -v /etc/passwd:/host/etc/passwd:ro \
        -v /etc/group:/host/etc/group:ro \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro

$SHIPA_CLIENT node-container-upgrade netdata -y --framework=shipa-framework

platforms=$(echo $PLATFORMS | tr " " "\n")

echo "waiting busybody daemons..."
sleep 30

for platform in $platforms;
do
   $SHIPA_CLIENT platform-add $platform
done

/scripts/install-dashboard.sh
