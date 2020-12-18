
# Documentation

Documentation for Shipa can be found at https://learn.shipa.io

# Defaults 

We create LoadBalancer service to expose Shipa to the internet:
1. 5000 -> docker registry
1. 8080 -> shipa api over http
1. 8081 -> shipa api over https

By default we use dynamic public IP set by a cloud-provider but there is a parameter to use static ip (if you have it):
```bash 
--set service.nginx.loadBalancerIP=35.192.15.168 
```

# Installation

The installation creates an admin user, and you have to set its email and password:
```bash
--set=auth.adminUser=....   
--set=auth.adminPassword=....    
```


## Configuring kubernetes cluster and helm chart
```bash

NAMESPACE=shipa-system
kubectl create namespace $NAMESPACE

helm version

#  Version 2 of helm uses Tiller to create workloads and thus requires two additional steps: 
# run this commond only if you use Helm 2
helm init
kubectl create clusterrolebinding kube-system-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

git clone https://github.com/shipa-corp/helm-chart
cd helm-chart

kubectl apply -f limits.yaml --namespace=$NAMESPACE

helm dep up 
```

## Installing shipa helm chart

To easily manage upgrades you could keep all overridden values in values.override.yaml

```bash
cat > values.override.yaml << EOF
auth:
  adminUser: <your email here>
  adminPassword: <your admin password> 
EOF
helm install . --name=shipa --timeout=1000 --namespace=$NAMESPACE -f values.override.yaml
```

## Upgrading shipa helm chart

```bash
helm upgrade shipa . --timeout=1000 --namespace=$NAMESPACE -f values.override.yaml
```

## Upgrading shipa helm chart if you have Pro license

We have two general ways how to execute helm upgrade if you have Pro license:
* Pass a license file to helm upgrade 

```bash
helm upgrade shipa . --timeout=1000 --namespace=$NAMESPACE -f values.override.yaml -f license.yaml
```
* Merge license key from a license file to values.override.yaml and execute helm upgrade as usual
```bash
cat license.yaml | grep "license:" >> values.override.yaml
```

# Shipa client

If you are looking to operate Shipa from your local machine, we have binaries of shipa client: https://learn.shipa.io/docs/downloading-the-shipa-client

# Collaboration/Contributing

We welcome all feedback or pull requests. If you have any questions feel free to reach us at info@shipa.io