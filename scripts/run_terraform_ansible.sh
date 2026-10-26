#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need terraform
step 1 'Initialize local provider and validate'
terraform -chdir=terraform init
terraform -chdir=terraform validate
# Preserve a pre-existing unmanaged file.
if [[ -e terraform/iot_config.env && ! -e terraform/terraform.tfstate ]]; then
  echo 'ERROR: unmanaged iot_config.env exists; inspect it before continuing'; exit 1
fi
step 2 'Plan local file creation: terraform/iot_config.env, PORT=1883 and BROKER=MQTT'
terraform -chdir=terraform plan -out=lab.tfplan
terraform -chdir=terraform show -no-color lab.tfplan
read -r -p 'Apply the displayed local file plan? Type yes: ' answer
[[ "$answer" == yes ]] || { echo 'Plan preserved; no apply performed'; exit 0; }
terraform -chdir=terraform apply lab.tfplan
step 3 'Verify exact generated contents'
printf 'PORT=1883\nBROKER=MQTT\n' | cmp - terraform/iot_config.env
if command -v ansible >/dev/null; then
  ansible localhost -i 'localhost,' -c local -m ansible.builtin.command -a "cat $ROOT/terraform/iot_config.env"
else
  echo 'SKIP: Ansible missing; install then run the README command'
fi
