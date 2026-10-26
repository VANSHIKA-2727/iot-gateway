#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
step 1 "Environment: $(uname -s) / $(uname -m)"
for tool in git python3 docker kubectl terraform ansible; do
  if command -v "$tool" >/dev/null; then echo "AVAILABLE: $tool"; else echo "MISSING: $tool"; fi
done
step 2 'Configuration files already exist. No software installed or resources applied.'
