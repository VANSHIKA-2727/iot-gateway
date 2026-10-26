#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need docker; need curl
docker info >/dev/null 2>&1 || { echo 'ERROR: Start Docker Desktop and wait for its engine'; exit 1; }
step 1 'Build local image iot-hub:latest'
docker build -t iot-hub:latest .
step 2 'Run container on localhost:8088'
if docker container inspect iot-hub >/dev/null 2>&1; then
  [[ "$(docker inspect -f '{{index .Config.Labels "lab.project"}}' iot-hub)" == iot-gateway ]] || { echo 'ERROR: unrelated container named iot-hub; choose a different name manually'; exit 1; }
  [[ "$(docker inspect -f '{{.Image}}' iot-hub)" == "$(docker image inspect -f '{{.Id}}' iot-hub:latest)" ]] || { echo 'ERROR: existing container uses an older image. Preserve it and choose a new container name manually.'; exit 1; }
  docker start iot-hub >/dev/null
else
  docker run -d --name iot-hub --label lab.project=iot-gateway -p 127.0.0.1:8088:80 iot-hub:latest
fi
step 3 'Verify image, running state, logs, and HTTP'
docker image inspect iot-hub:latest --format '{{.Id}}'
[[ "$(docker inspect -f '{{.State.Running}}' iot-hub)" == true ]]
curl --fail --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 http://localhost:8088 | grep -qx 'Smart Hub Online'
docker logs iot-hub 2>&1 | grep 'Smart Hub Online'
docker port iot-hub 80
