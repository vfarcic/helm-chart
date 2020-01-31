#!/bin/sh

. /init/common.sh

set_public_ips

is_token_set() {
    GUARDIAN_TOKEN=$(kubectl get secret/shipa-guardian -o json | jq ".data[\"token\"]")
    LENGTH=${#GUARDIAN_TOKEN}
    if [ "$LENGTH" -gt "10" ]; then
      return 0
    fi
    return 1
}

set_guardian_variables() {
  TOKEN=$(/bin/shipad token | base64)
  kubectl get secrets shipa-guardian -o json \
          | jq ".data[\"token\"] |= \"$TOKEN\"" \
          | kubectl apply -f -

  kubectl set env deployment/$GUARDIAN_SERVICE GUARDIAN_HOST="$NGINX_ADDRESS"
  kubectl scale deployment/$GUARDIAN_SERVICE --replicas=0
  echo "stopping guardian"
  sleep 15
  echo "running guardian"
  kubectl scale deployment/$GUARDIAN_SERVICE --replicas=1
}


if is_token_set; then
  echo "Skip creating root user"
  exit 0
fi

OUTPUT=$(/bin/shipad root-user-create $USERNAME << EOF
$PASSWORD
$PASSWORD
EOF
)

echo $OUTPUT
echo "-------"

if echo $OUTPUT | grep "Root user successfully updated"; then
  set_guardian_variables
  exit 0
fi

if echo $OUTPUT | grep "Root user successfully created"; then
  set_guardian_variables
  exit 0
fi

echo "Can't create root user"
sleep 10
exit 1

