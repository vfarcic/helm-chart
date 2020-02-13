#!/bin/bash

helm install shipa . \
--timeout=15m \
--set=auth.adminPassword=shipa2020 \
--set=service.traefik.serviceType=ClusterIP \
--set=service.nginx.serviceType=ClusterIP \
--set=service.nginx.clusterIP=10.100.10.10 \
--set=dashboard.enabled=false \
--set=platforms={}
#--set=platforms={python,go}
