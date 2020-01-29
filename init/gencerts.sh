#!/bin/bash

CERTIFICATES_DIRECTORY=/tmp/certs
mkdir $CERTIFICATES_DIRECTORY

sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /init/csr-shipa-ca.json > $CERTIFICATES_DIRECTORY/csr-shipa-ca.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /init/csr-docker-registry.json > $CERTIFICATES_DIRECTORY/csr-docker-registry.json
sed "s/SHIPA_PUBLIC_IP/$NGINX_ADDRESS/g" /init/csr-docker-cluster.json > $CERTIFICATES_DIRECTORY/csr-docker-cluster.json

cfssl gencert -initca $CERTIFICATES_DIRECTORY/csr-shipa-ca.json | cfssljson -bare $CERTIFICATES_DIRECTORY/ca
cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=server \
    -hostname="$NGINX_ADDRESS" \
    $CERTIFICATES_DIRECTORY/csr-docker-registry.json | cfssljson -bare $CERTIFICATES_DIRECTORY/docker-registry

cfssl gencert \
    -ca=$CERTIFICATES_DIRECTORY/ca.pem \
    -ca-key=$CERTIFICATES_DIRECTORY/ca-key.pem \
    -profile=server \
    -hostname="$NGINX_ADDRESS" \
    $CERTIFICATES_DIRECTORY/csr-docker-cluster.json | cfssljson -bare $CERTIFICATES_DIRECTORY/docker-cluster

rm -f $CERTIFICATES_DIRECTORY/*.csr
rm -f $CERTIFICATES_DIRECTORY/*.json

CA_CERT=$(cat $CERTIFICATES_DIRECTORY/ca.pem | base64)
CA_KEY=$(cat $CERTIFICATES_DIRECTORY/ca-key.pem | base64)

DOCKER_CLUSTER_CERT=$(cat $CERTIFICATES_DIRECTORY/docker-cluster.pem | base64)
DOCKER_CLUSTER_KEY=$(cat $CERTIFICATES_DIRECTORY/docker-cluster-key.pem | base64)

DOCKER_REGISTRY_CERT=$(cat $CERTIFICATES_DIRECTORY/docker-registry.pem | base64)
DOCKER_REGISTRY_KEY=$(cat $CERTIFICATES_DIRECTORY/docker-registry-key.pem | base64)

# FIXME: name of secret
kubectl get secrets shipa-certificates -o json \
        | jq ".data[\"ca.pem\"] |= \"$CA_CERT\"" \
        | jq ".data[\"ca-key.pem\"] |= \"$CA_KEY\"" \
        | jq ".data[\"cert.pem\"] |= \"$DOCKER_CLUSTER_CERT\"" \
        | jq ".data[\"key.pem\"] |= \"$DOCKER_CLUSTER_KEY\"" \
        | jq ".data[\"tls.crt\"] |= \"$DOCKER_REGISTRY_CERT\"" \
        | jq ".data[\"tls.key\"] |= \"$DOCKER_REGISTRY_KEY\"" \
        | kubectl apply -f -

kubectl set env deployment/$REGISTRY_SERVICE REGISTRY_AUTH_TOKEN_REALM="http://$NGINX_ADDRESS:8080/docker-auth"

echo "CA:"
openssl x509 -in $CERTIFICATES_DIRECTORY/ca.pem -text -noout

echo "Docker registry:"
openssl x509 -in $CERTIFICATES_DIRECTORY/docker-registry.pem -text -noout

echo "Docker cluster:"
openssl x509 -in $CERTIFICATES_DIRECTORY/docker-cluster.pem -text -noout
