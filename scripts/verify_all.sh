#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures+1)); }
skip() { echo "SKIP: $*"; }
step 1 'Static files'
if grep -qx 'PORT=1883' mqtt.conf; then pass 'MQTT config'; else fail 'MQTT config'; fi
for f in scripts/*.sh; do
  if bash -n "$f"; then pass "Shell syntax: $f"; else fail "Shell syntax: $f"; fi
done
if command -v python3 >/dev/null; then
  if python3 -c 'import ast; from pathlib import Path; ast.parse(Path("docker/server.py").read_text())'; then pass 'Python syntax'; else fail 'Python syntax'; fi
else skip 'Python unavailable'; fi
step 2 'Git release'
if command -v git >/dev/null && [[ -d .git ]]; then
  if [[ "$(git symbolic-ref --short HEAD)" == main ]] &&
     [[ "$(git rev-parse main)" == "$(git rev-parse release-v6.0)" ]] &&
     [[ "$(git rev-parse main)" == "$(git rev-parse 'v6.0.0-release^{commit}')" ]] &&
     [[ -z "$(git status --porcelain)" ]]; then pass 'Git branches, tag, clean main'; else fail 'Git release'; fi
else skip 'Git release not initialized'; fi
step 3 'Docker'
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  if docker image inspect iot-hub:latest >/dev/null 2>&1; then pass 'Docker image'; else fail 'Docker image'; fi
  if [[ "$(docker inspect -f '{{.State.Running}}' iot-hub 2>/dev/null || true)" == true ]]; then pass 'Container running'; else fail 'Container running'; fi
  if docker logs iot-hub 2>&1 | grep -q 'Smart Hub Online'; then pass 'Container logs'; else fail 'Container logs'; fi
  if command -v curl >/dev/null; then
    if curl --max-time 5 -fsS http://localhost:8088 | grep -qx 'Smart Hub Online'; then pass 'Docker HTTP'; else fail 'Docker HTTP'; fi
  else skip 'curl missing'; fi
else skip 'Docker CLI/daemon unavailable'; fi
step 4 'Kubernetes'
if command -v kubectl >/dev/null && kubectl config current-context >/dev/null 2>&1 && kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
  if [[ "$(kubectl get deployment iot-core -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == 2 ]]; then pass 'Two ready replicas'; else fail 'Deployment readiness'; fi
  if [[ "$(kubectl get pods -l service=iot-core --field-selector=status.phase=Running -o name | wc -l | tr -d ' ')" == 2 ]]; then pass 'Two running pods with matching labels'; else fail 'Pod count/labels'; fi
  kubectl get pods -l service=iot-core --show-labels || true
  if [[ "$(kubectl get service iot-core -o jsonpath='{.spec.type}:{.spec.ports[0].port}:{.spec.ports[0].targetPort}:{.spec.ports[0].nodePort}' 2>/dev/null)" == NodePort:80:80:30098 ]]; then pass 'NodePort configuration'; else fail 'NodePort configuration'; fi
  if command -v curl >/dev/null && curl --max-time 3 -fsS http://localhost:30098 >/dev/null; then pass 'NodePort HTTP on localhost'; else skip 'Localhost NodePort not reachable; use documented port-forward verification'; fi
else skip 'No reachable Kubernetes context'; fi
step 5 'Terraform and Ansible'
if command -v terraform >/dev/null; then
  if [[ -d terraform/.terraform ]]; then
    if terraform -chdir=terraform validate; then pass 'Terraform validation'; else fail 'Terraform validation'; fi
  else skip 'Terraform provider not initialized'; fi
else skip 'Terraform missing'; fi
if [[ -f terraform/iot_config.env ]]; then
  if printf 'PORT=1883\nBROKER=MQTT\n' | cmp - terraform/iot_config.env; then pass 'Generated file'; else fail 'Generated file contents'; fi
  if command -v ansible >/dev/null; then
    if ansible localhost -i 'localhost,' -c local -m ansible.builtin.command -a "cat $ROOT/terraform/iot_config.env"; then pass 'Ansible local read'; else fail 'Ansible local read'; fi
  else skip 'Ansible missing'; fi
else skip 'Terraform local file not generated'; fi
step 6 'External services'
skip 'Jenkins pipeline requires a configured job and build; not executed by this read-only check'
skip 'Jira requires approved access and explicit confirmation; no issue/sprint mutations performed'
echo "Verification complete: $failures failure(s). SKIP means unverified, not passed."
[[ "$failures" == 0 ]]
