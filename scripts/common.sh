#!/bin/sh

wait_public_ip() {
    SERVICE_TYPE=$1;
    SERVICE_NAME=$2;

    if [ "${SERVICE_TYPE:-}" == "ClusterIP" ]; then
      ClusterIP=$(kubectl get svc $SERVICE_NAME -o jsonpath="{.spec.clusterIP}")
      echo $ClusterIP
    else
      external_ip=""
      while [ -z $external_ip ]; do
          external_ip=$(kubectl get svc $SERVICE_NAME -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

          if [ -z $external_ip ]; then
            # fallback to .hostname, as on EKS .hostname is populated instead of .ip
            external_ip=$(kubectl get svc $SERVICE_NAME -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
          fi

          sleep 2
      done
      echo $external_ip
    fi
}

set_public_ips() {
  echo "Waiting for nginx ingress to be ready"
  NGINX_ADDRESS=$(wait_public_ip $NGINX_SERVICE_TYPE $NGINX_SERVICE)
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

