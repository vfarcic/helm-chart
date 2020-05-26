
# Defaults 

We create two LoadBalancers to expose services to the internet.    
The first public IP (ingress-nginx) is used to open ports: 
1. 22 -> guardian
1. 5000 -> docker registry
1. 8080 -> shipa api

The second public IP (traefik) is used to open: 
1. 80 -> http access for apps
1. 443 -> https access for apps.

By default we use dynamic public IPs set by a cloud-provider but there are options to use static ips:
```bash 
--set service.traefik.loadBalancerIP=35.192.15.168 
--set service.nginx.loadBalancerIP=35.192.15.168 
```

There is no hardcoded password for admin user so `--set=auth.adminPassword=....` is required.

# Installation

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

# to successfully deploy shipa resources like DaemonSets to run busybody/netdata, pods to build platforms and so on
# we should label nodes (at least one)
kubectl label $(kubectl get nodes -o name) "shipa.io/pool=theonepool" --overwrite

helm dep up 
```

## Installing shipa helm chart

To easily manage upgrades you could keep all overridden values in values.override.yaml

```bash
cat > values.override.yaml << EOF
auth:
  adminUser: <your email here>
  adminPassword: shipa2020
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

# Dev environment

There is an interesting project from Cloud Native: [https://www.telepresence.io/](https://www.telepresence.io/)

Steps to run development environment:
* Install telepresence: [here's manual](https://www.telepresence.io/reference/install).
* Install Intellij IDEA [plugin](https://www.telepresence.io/tutorials/intellij)
* Run minikube cluster
```kubectl label node minikube shipa.io/pool=theonepool```
* Install the helm chart. It takes up to 5-8 minutes
```
helm install shipa . \ 
--timeout=15m \
--set=auth.adminPassword=shipa2020 \
--set=service.traefik.serviceType=ClusterIP \
--set=service.nginx.serviceType=ClusterIP \
--set=service.nginx.clusterIP=10.100.10.10 \
--set=dashboard.enabled=false \
--set=platforms=[]
```   
* run telepresence: 
```
telepresence --swap-deployment shipa-api --env-json shipa-api.json
```
* Configure IDEA to inject enviroment variables from shipa-api.json:
[here](https://www.telepresence.io/tutorials/intellij)
* Run ShipaAPI in IDE. 
* Work with shipa client
```
shipa target-add shipa-api http://shipa-ingress-nginx:8080 -s 
```

* Use ./cleanup.sh to cleanup the cluster.

If you want to expose mongodb, there is ./dev/mongodb.yaml

#### Notes about dev environment

The helm chart exposed two kubernetes services, so with minikube it's possible with two hacks:
1. Change nginx and traefik services' types to ClusterIP. You can do it directly in values.yaml or 
run the helm install command with additional parameters:
   ```
   helm install shipa ... \
   --set=service.traefik.serviceType=ClusterIP \
   --set=service.nginx.serviceType=ClusterIP
   ```
   
1. Run minikube tunnel, it fixes the services and injects private 10.\*.\*.\* ips instead of public ones.



