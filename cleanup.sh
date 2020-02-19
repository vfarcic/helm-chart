#!/bin/bash

NAMESPACE="default"
helm delete --namespace=$NAMESPACE shipa  --no-hooks

kubectl --namespace=$NAMESPACE delete job.batch/shipa-init-job-1 --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete deployment dashboard-web-1 --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete ds node-container-netdata-all --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete ds node-container-netdata-pool-theonepool --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete ds node-container-busybody-pool-theonepool  --ignore-not-found=true

kubectl --namespace=$NAMESPACE delete service/dashboard-web-1 --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete service/dashboard-web-1-units --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete pod python-image-build --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete pod dashboard-v1-deploy --ignore-not-found=true
kubectl --namespace=$NAMESPACE delete configmap/shipa-leader-nginx --ignore-not-found=true

kubectl delete ds node-container-netdata-all --ignore-not-found=true
kubectl delete ds node-container-netdata-pool-theonepool --ignore-not-found=true
kubectl delete ds node-container-busybody-pool-theonepool  --ignore-not-found=true
kubectl delete pod dashboard-v1-deploy --ignore-not-found=true
