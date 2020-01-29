#!/bin/bash

helm delete shipa

kubectl delete job.batch/shipa-init-job-1 --ignore-not-found=true
kubectl delete deployment dashboard-web-1 --ignore-not-found=true
kubectl delete ds node-container-netdata-all --ignore-not-found=true
kubectl delete ds node-container-netdata-pool-theonepool --ignore-not-found=true
kubectl delete ds node-container-busybody-pool-theonepool  --ignore-not-found=true

kubectl delete service/dashboard-web-1 --ignore-not-found=true
kubectl delete service/dashboard-web-1-units --ignore-not-found=true
kubectl delete pod python-image-build --namespace=shipa --ignore-not-found=true
kubectl delete pod dashboard-v1-deploy --namespace=shipa --ignore-not-found=true
kubectl delete configmap/shipa-ingress-controller-leader-nginx --ignore-not-found=true

