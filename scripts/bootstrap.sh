#!/bin/sh

. /scripts/common.sh

set_public_ips

echo "Prepare shipa.conf"
cp -v /etc/shipa-default/shipa.conf /etc/shipa/shipa.conf
sed -i "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /etc/shipa/shipa.conf
sed -ie "s/SHIPA_ORGANIZATION_ID/$SHIPA_ORGANIZATION_ID/g" /etc/shipa/shipa.conf

echo "shipa.conf: "
cat /etc/shipa/shipa.conf

if is_shipa_initialized; then
  echo "Skip bootstrapping because shipa is already initialized"
  exit 0
fi

CERTIFICATES_DIRECTORY=/tmp/certs
mkdir $CERTIFICATES_DIRECTORY

sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-shipa-ca.json > $CERTIFICATES_DIRECTORY/csr-shipa-ca.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-docker-registry.json > $CERTIFICATES_DIRECTORY/csr-docker-registry.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-docker-cluster.json > $CERTIFICATES_DIRECTORY/csr-docker-cluster.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-etcd.json > $CERTIFICATES_DIRECTORY/csr-etcd.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-api-config.json > $CERTIFICATES_DIRECTORY/csr-api-config.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /scripts/csr-api-server.json > $CERTIFICATES_DIRECTORY/csr-api-server.json
sed "s/ETCD_SERVICE/$ETCD_SERVICE/g" --in-place $CERTIFICATES_DIRECTORY/csr-etcd.json

sed "s/SHIPA_API_CNAMES/$SHIPA_API_CNAMES/g" --in-place $CERTIFICATES_DIRECTORY/csr-docker-registry.json
sed "s/SHIPA_API_CNAMES/$SHIPA_API_CNAMES/g" --in-place $CERTIFICATES_DIRECTORY/csr-docker-cluster.json
sed "s/SHIPA_API_CNAMES/$SHIPA_API_CNAMES/g" --in-place $CERTIFICATES_DIRECTORY/csr-etcd.json
sed "s/SHIPA_API_CNAMES/$SHIPA_API_CNAMES/g" --in-place $CERTIFICATES_DIRECTORY/csr-api-server.json

jq 'fromstream(tostream | select(length == 1 or .[1] != ""))' $CERTIFICATES_DIRECTORY/csr-docker-registry.json > file.tmp && mv file.tmp $CERTIFICATES_DIRECTORY/csr-docker-registry.json
jq 'fromstream(tostream | select(length == 1 or .[1] != ""))' $CERTIFICATES_DIRECTORY/csr-docker-cluster.json > file.tmp && mv file.tmp $CERTIFICATES_DIRECTORY/csr-docker-cluster.json
jq 'fromstream(tostream | select(length == 1 or .[1] != ""))' $CERTIFICATES_DIRECTORY/csr-etcd.json > file.tmp && mv file.tmp $CERTIFICATES_DIRECTORY/csr-etcd.json
jq 'fromstream(tostream | select(length == 1 or .[1] != ""))' $CERTIFICATES_DIRECTORY/csr-api-server.json > file.tmp && mv file.tmp $CERTIFICATES_DIRECTORY/csr-api-server.json

cp /scripts/csr-etcd-client.json $CERTIFICATES_DIRECTORY/csr-etcd-client.json
cp /scripts/csr-client-ca.json $CERTIFICATES_DIRECTORY/csr-client-ca.json
cp /scripts/csr-netdata-client.json $CERTIFICATES_DIRECTORY/csr-netdata-client.json

cfssl gencert -initca $CERTIFICATES_DIRECTORY/csr-shipa-ca.json | cfssljson -bare $CERTIFICATES_DIRECTORY/ca
cfssl gencert -initca $CERTIFICATES_DIRECTORY/csr-client-ca.json | cfssljson -bare $CERTIFICATES_DIRECTORY/client-ca
cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=server \
    $CERTIFICATES_DIRECTORY/csr-docker-registry.json | cfssljson -bare $CERTIFICATES_DIRECTORY/docker-registry

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=server \
    $CERTIFICATES_DIRECTORY/csr-docker-cluster.json | cfssljson -bare $CERTIFICATES_DIRECTORY/docker-cluster

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=server \
    $CERTIFICATES_DIRECTORY/csr-etcd.json | cfssljson -bare $CERTIFICATES_DIRECTORY/etcd-server

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=client \
    $CERTIFICATES_DIRECTORY/csr-etcd-client.json | cfssljson -bare $CERTIFICATES_DIRECTORY/etcd-client

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -config=$CERTIFICATES_DIRECTORY/csr-api-config.json \
    -profile=server \
    $CERTIFICATES_DIRECTORY/csr-api-server.json | cfssljson -bare $CERTIFICATES_DIRECTORY/api-server

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/client-ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/client-ca-key.pem \
    -profile=client \
    $CERTIFICATES_DIRECTORY/csr-netdata-client.json | cfssljson -bare $CERTIFICATES_DIRECTORY/netdata-client

rm -f $CERTIFICATES_DIRECTORY/*.csr
rm -f $CERTIFICATES_DIRECTORY/*.json

CA_CERT=$(cat $CERTIFICATES_DIRECTORY/ca.pem | base64)
CA_KEY=$(cat $CERTIFICATES_DIRECTORY/ca-key.pem | base64)

CLIENT_CA_CERT=$(cat $CERTIFICATES_DIRECTORY/client-ca.pem | base64)
CLIENT_CA_KEY=$(cat $CERTIFICATES_DIRECTORY/client-ca-key.pem | base64)

NETDATA_CLIENT_CERT=$(cat $CERTIFICATES_DIRECTORY/netdata-client.pem | base64)
NETDATA_CLIENT_KEY=$(cat $CERTIFICATES_DIRECTORY/netdata-client-key.pem | base64)

DOCKER_CLUSTER_CERT=$(cat $CERTIFICATES_DIRECTORY/docker-cluster.pem | base64)
DOCKER_CLUSTER_KEY=$(cat $CERTIFICATES_DIRECTORY/docker-cluster-key.pem | base64)

DOCKER_REGISTRY_CERT=$(cat $CERTIFICATES_DIRECTORY/docker-registry.pem | base64)
DOCKER_REGISTRY_KEY=$(cat $CERTIFICATES_DIRECTORY/docker-registry-key.pem | base64)

ETCD_SERVER_CERT=$(cat $CERTIFICATES_DIRECTORY/etcd-server.pem | base64)
ETCD_SERVER_KEY=$(cat $CERTIFICATES_DIRECTORY/etcd-server-key.pem | base64)

ETCD_CLIENT_CERT=$(cat $CERTIFICATES_DIRECTORY/etcd-client.pem | base64)
ETCD_CLIENT_KEY=$(cat $CERTIFICATES_DIRECTORY/etcd-client-key.pem | base64)

API_SERVER_CERT=$(cat $CERTIFICATES_DIRECTORY/api-server.pem | base64)
API_SERVER_KEY=$(cat $CERTIFICATES_DIRECTORY/api-server-key.pem | base64)


# FIXME: name of secret
kubectl get secrets shipa-certificates -o json \
        | jq ".data[\"ca.pem\"] |= \"$CA_CERT\"" \
        | jq ".data[\"ca-key.pem\"] |= \"$CA_KEY\"" \
        | jq ".data[\"client-ca.crt\"] |= \"$CLIENT_CA_CERT\"" \
        | jq ".data[\"client-ca.key\"] |= \"$CLIENT_CA_KEY\"" \
        | jq ".data[\"netdata-client.crt\"] |= \"$NETDATA_CLIENT_CERT\"" \
        | jq ".data[\"netdata-client.key\"] |= \"$NETDATA_CLIENT_KEY\"" \
        | jq ".data[\"cert.pem\"] |= \"$DOCKER_CLUSTER_CERT\"" \
        | jq ".data[\"key.pem\"] |= \"$DOCKER_CLUSTER_KEY\"" \
        | jq ".data[\"tls.crt\"] |= \"$DOCKER_REGISTRY_CERT\"" \
        | jq ".data[\"tls.key\"] |= \"$DOCKER_REGISTRY_KEY\"" \
        | jq ".data[\"etcd-server.crt\"] |= \"$ETCD_SERVER_CERT\"" \
        | jq ".data[\"etcd-server.key\"] |= \"$ETCD_SERVER_KEY\"" \
        | jq ".data[\"etcd-client.crt\"] |= \"$ETCD_CLIENT_CERT\"" \
        | jq ".data[\"etcd-client.key\"] |= \"$ETCD_CLIENT_KEY\"" \
        | jq ".data[\"api-server.crt\"] |= \"$API_SERVER_CERT\"" \
        | jq ".data[\"api-server.key\"] |= \"$API_SERVER_KEY\"" \
        | kubectl apply -f -

kubectl scale deployment/$REGISTRY_SERVICE --replicas=0
echo "stopping docker registry"
sleep 25
echo "running docker registry"
kubectl set env deployment/$REGISTRY_SERVICE REGISTRY_AUTH_TOKEN_REALM="http://$NGINX_ADDRESS:$SHIPA_PORT/docker-auth"
kubectl scale deployment/$REGISTRY_SERVICE --replicas=1

echo "CA:"
openssl x509 -in $CERTIFICATES_DIRECTORY/ca.pem -text -noout

echo "Docker registry:"
openssl x509 -in $CERTIFICATES_DIRECTORY/docker-registry.pem -text -noout

echo "Docker cluster:"
openssl x509 -in $CERTIFICATES_DIRECTORY/docker-cluster.pem -text -noout

echo "Etcd server:"
openssl x509 -in $CERTIFICATES_DIRECTORY/etcd-server.pem -text -noout

echo "Etcd client:"
openssl x509 -in $CERTIFICATES_DIRECTORY/etcd-client.pem -text -noout
