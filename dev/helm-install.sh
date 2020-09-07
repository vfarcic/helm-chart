#!/bin/bash

#
# Delete PVs
#
# kubectl get pv -o name | xargs kubectl delete

helm install shipa . \
--timeout=15m \
--set=auth.adminPassword=shipa2020 \
--set=service.traefik.serviceType=ClusterIP \
--set=service.nginx.serviceType=ClusterIP \
--set=service.nginx.clusterIP=10.100.10.10 \
--set=dashboard.enabled=false \
--set=platforms={} \
--set=guardian.persistence.homeGit.size=1Gi \
--set=guardian.persistence.repositories.size=1Gi \
--set=postgres.persistence.size=1Gi \
--set=docker-registry.persistence.size=5Gi \
--set=mongodb-replicaset.persistentVolume.size=2Gi \
#--set=platforms={python,go}

# Set up route
# sudo ip route add 10.100.10.10/32 dev vboxnet0 via $(minikube ip)
#