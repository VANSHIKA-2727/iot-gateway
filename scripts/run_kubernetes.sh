#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need kubectl
step 1 'Check selected cluster'
kubectl config current-context
kubectl cluster-info --request-timeout=5s >/dev/null
[[ "${1:-}" == --apply ]] || { echo 'Review k8s/ then rerun with --apply to create/update iot-core in the current namespace.'; exit 0; }
# Refuse to adopt resources unless this script previously annotated them.
for resource in deployment/iot-core service/iot-core; do
  if kubectl get "$resource" >/dev/null 2>&1; then
    [[ "$(kubectl get "$resource" -o jsonpath='{.metadata.annotations.lab-owner}')" == iot-gateway ]] || { echo "ERROR: $resource exists without lab ownership; inspect manually"; exit 1; }
  fi
done
step 2 'Apply lab resources in current context and namespace'
kubectl apply -f k8s/
kubectl annotate deployment/iot-core service/iot-core lab-owner=iot-gateway --overwrite
step 3 'Verify rollout, replicas, labels, service'
kubectl rollout status deployment/iot-core --timeout=120s
[[ "$(kubectl get deployment iot-core -o jsonpath='{.status.readyReplicas}')" == 2 ]]
kubectl get pods -l service=iot-core --show-labels
[[ "$(kubectl get pods -l service=iot-core --field-selector=status.phase=Running -o name | wc -l | tr -d ' ')" == 2 ]]
kubectl get service iot-core -o wide
[[ "$(kubectl get service iot-core -o jsonpath='{.spec.type}:{.spec.ports[0].port}:{.spec.ports[0].targetPort}:{.spec.ports[0].nodePort}')" == NodePort:80:80:30098 ]]
echo 'HTTP: try curl --fail http://localhost:30098 if your cluster exposes NodePorts on localhost.'
echo 'Otherwise: kubectl port-forward service/iot-core 8089:80; in another terminal: curl --fail http://localhost:8089'
