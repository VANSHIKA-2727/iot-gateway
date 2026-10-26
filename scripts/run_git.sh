#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need git
step 1 'Initialize an isolated repository'
if [[ ! -d .git ]]; then
  git init -b main .
fi
[[ "$(git rev-parse --show-toplevel)" == "$ROOT" ]] || { echo 'ERROR: repository root mismatch'; exit 1; }
git config user.name >/dev/null || { echo 'Set git config user.name first'; exit 1; }
git config user.email >/dev/null || { echo 'Set git config user.email first'; exit 1; }
if git rev-parse --verify refs/tags/v6.0.0-release >/dev/null 2>&1; then
  echo 'Release already exists; verify without rewriting history.'
else
  [[ -z "$(git status --porcelain)" || -z "$(git rev-list --all)" ]] || { echo 'ERROR: commit or preserve existing changes first'; exit 1; }
  [[ "$(git symbolic-ref --short HEAD)" == main ]] || { echo 'ERROR: start on main'; exit 1; }
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    git add . ':!mqtt.conf'
    git commit -m 'Initialize IoT gateway lab'
  fi
  step 2 'Commit MQTT configuration on release-v6.0'
  if git show-ref --verify --quiet refs/heads/release-v6.0; then
    echo 'ERROR: existing release branch needs manual inspection'; exit 1
  fi
  git switch -c release-v6.0
  grep -qx 'PORT=1883' mqtt.conf
  git add mqtt.conf
  git commit -m 'Configure MQTT port 1883'
  git switch main
  git merge --ff-only release-v6.0
  git tag -a v6.0.0-release -m 'IoT gateway v6.0.0 release'
fi
step 3 'Verify release branches, history, and tag'
git branch -v
git log --oneline --decorate --all -5
git show --no-patch v6.0.0-release
[[ "$(git rev-parse main)" == "$(git rev-parse release-v6.0)" ]]
[[ "$(git rev-parse main)" == "$(git rev-parse 'v6.0.0-release^{commit}')" ]]
