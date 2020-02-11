
# Defaults 

We create two LoadBalancers to expose services to the internet.    
The first public IP (ingress-nginx) is used to open ports: 
1. 22 -> guardian
1. 5000 -> docker registry
1. 8080 -> shipa api
1. 9090 -> prometheus
1. 9091 -> prometheus pushgateway.

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

```bash

helm version

#  Version 2 of helm uses Tiller to create workloads and thus requires two additional steps: 
# run this commond only if you use Helm 2
helm init
kubectl create clusterrolebinding kube-system-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

git clone https://github.com/shipa-corp/helm-chart
cd helm-chart

kubectl apply -f limits.yaml

# to successfully deploy shipa resources like DaemonSets to run busybody/netdata, pods to build platforms and so on
# we should label nodes (at least one)
kubectl label $(kubectl get nodes -o name | head -n 2) "shipa.io/pool=theonepool" --overwrite

helm dep up 

# Please don't change "shipa" chart name for now
helm install . --name=shipa --timeout=1000 --set=auth.adminPassword=shipa2020
--set=defaultPool=theonepool

```