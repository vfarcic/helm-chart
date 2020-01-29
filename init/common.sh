#!/bin/sh

wait_public_ip() {
    SERVICE_TYPE=$1;
    SERVICE_NAME=$2;

    if [ "${SERVICE_TYPE:-}" == "NodePort" ]; then
      NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services $SERVICE_NAME)
      NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
      echo $NODE_IP:$NODE_PORT
    else
      external_ip=""
      while [ -z $external_ip ]; do
          external_ip=$(kubectl get svc $SERVICE_NAME --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
          sleep 2
      done
      echo $external_ip
    fi
}

set_public_ips() {
  echo "Waiting for traefik to be ready"
  TRAEFIK_ADDRESS=$(wait_public_ip LoadBalancer $TRAEFIK_SERVICE)
  echo "shipa address: $TRAEFIK_ADDRESS"

  echo "Waiting for nginx ingress to be ready"
  NGINX_ADDRESS=$(wait_public_ip LoadBalancer $NGINX_SERVICE)
  echo "shipa address: $NGINX_ADDRESS"
}

is_shipa_initialized() {

    # By default we create secret with empty certificates
    # and save them to the secret as a result of the first run of boostrap.sh

    CA=$(kubectl get secret/shipa-certificates -o json | jq ".data[\"ca.pem\"]")
    LENGTH=${#CA}

    if [ "$LENGTH" -gt "100" ]; then
      return 0
    fi
    return 1
}

