# IoT Sensor & MQTT Broker Gateway — DevOps Practical

This lab demonstrates Git releases, Jira sprint administration, Jenkins CI, Docker HTTP hosting, Kubernetes, and Terraform/Ansible. The MQTT configuration is an exam artifact: this project does not implement an MQTT broker or sensor ingestion. Docker serves `Smart Hub Online`; Kubernetes runs the separately required nginx welcome page.

## Start here

Open this folder in VS Code (File → Open Folder), then use Terminal → New Terminal. Run commands from this directory. No script installs software, deletes resources, pushes to a remote, or changes Jira. Scripts stop on errors. Verification reports PASS, FAIL, or SKIP; skipped work has not been proven to work.

```bash
./scripts/setup.sh
./scripts/run_git.sh
./scripts/verify_all.sh
```

`setup.sh` detects macOS/arm64 and available commands. It does not generate or apply infrastructure. `common.sh` anchors every script to this directory even when invoked elsewhere. Scripts require Bash (the macOS bundled Bash is sufficient).

## Tools and responsibilities

| Tool | Purpose in this lab |
|---|---|
| Git | Save changes, work on a branch, merge and tag a release |
| Jira | Track issue workflow and sprint progress |
| Jenkins | Run an SCM-driven Declarative Pipeline |
| Docker | Package and run the lightweight Python HTTP service on Alpine |
| Kubernetes | Maintain two nginx replicas and expose a NodePort |
| Terraform | Declare and create one local configuration file |
| Ansible | Execute a local ad-hoc file read |

## A. Git — release v6.0

`./scripts/run_git.sh` creates an independent nested repository with `main`. It first commits the lab scaffolding, excluding `mqtt.conf`, so that `main` is a real branch before creating the release branch. It then commits `mqtt.conf` on `release-v6.0`, fast-forwards `main`, and creates the annotated tag. A rerun verifies the existing release without rewriting it. It refuses unexpected existing work or branches. An interrupted first run may require inspection rather than automatic recovery.

Equivalent first-run commands, for a fresh folder only (do not repeat after initialization):

```bash
git init -b main
git add . ':!mqtt.conf'
git commit -m "Initialize IoT gateway lab"
git switch -c release-v6.0
printf 'PORT=1883\n' > mqtt.conf
git add mqtt.conf
git commit -m "Configure MQTT port 1883"
git switch main
git merge --ff-only release-v6.0
git tag -a v6.0.0-release -m "IoT gateway v6.0.0 release"
git branch -v
git log --oneline --decorate --all
git show --no-patch v6.0.0-release
```

Expected: two commits, both branches at the configuration commit, `* main`, and tag `v6.0.0-release`. A fast-forward is a valid merge; there is no unnecessary merge commit. If identity is missing, configure it **locally** after `git init`: `git config user.name "Your Name"` and `git config user.email "your-email@example.com"`. Do not reset or delete an existing repository to fix errors.

## B. Jira — manual browser checklist and approval gate

No approved Jira connector was exposed in this session. No credential values were read or stored, and no Jira result is claimed. An environment token alone would not establish an approved API connection. Do not paste tokens into files or terminal history.

1. Sign in to your institution's Jira site. Use Projects (or Spaces in newer navigation) → your IoT project. Verify the project key is `IOT`; do not infer a site URL.
2. Use Search → advanced issue search (JQL): `key in (IOT-10, IOT-20)`. Open each issue, inspect current status, project, sprint membership, and status dropdown transitions. Some workflows require intermediate transitions or resolution fields.
3. Record both current statuses and permitted paths to Done. **Obtain explicit confirmation before changing either issue.** Then select the permitted Done transition and verify status/history for each issue.
4. Project → correct Scrum board → Active sprints. Identify the active `Sprint-IoT-Ingest` and verify its board, dates, and all remaining issues. Review where unfinished issues will move. A matching name alone is insufficient if several boards use it.
5. **Obtain explicit confirmation before completing the sprint.** Select Complete sprint (sometimes in the sprint menu), review the dialog, choose a destination for unfinished work, then confirm. Requires appropriate sprint-management permissions. Do not start another sprint unless asked.
6. Board/project → Reports → Burndown Chart (or Sprint burndown), choose `Sprint-IoT-Ingest`. Review ideal versus actual remaining work, scope changes, completed/incomplete issues, and estimation settings. Preserve a screenshot for your exam. UI labels vary by project type; Reports or Sprints may need enabling.

A Done status should map to the board's completion column. Zero remaining work is expected only if all counted work is complete; closing a sprint does not guarantee a zero burndown. Atlassian's [burndown guide](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-sprint-burndown-report/) explains the report.

## C. Jenkins Declarative Pipeline

The Jenkinsfile has exactly three stages: **Git Pull**, **IoT Verification**, **Image Packaging**. `checkout scm` checks out the revision configured by the job. It is more appropriate than a hardcoded `git pull` in a potentially fresh agent workspace. Default checkout is disabled to avoid duplicate checkouts. Configuration validation precedes packaging, and packaging checks Docker CLI and daemon access on the **Jenkins agent**, not just on your Mac.

No Jenkins CLI was found and `http://localhost:8080` was not reachable. This does not prove a remote Jenkins instance is absent. The Jenkinsfile has not been validated by Jenkins or executed.

Setup (browser work required):

1. Use a lab-provided Jenkins server, or install a supported local LTS with Homebrew: `brew install jenkins-lts`, then `brew services start jenkins-lts`. These install/start commands change system state; run them only when ready. Follow the printed URL/unlock instructions, keep the admin password private, and install suggested plugins including Pipeline and Git. Check the [official macOS setup](https://www.jenkins.io/doc/book/installing/macos/) for current prerequisites.
2. Ensure the chosen Unix agent has Git and Docker CLI on PATH and access to a running Docker daemon. Homebrew services may not inherit your interactive shell PATH (`/opt/homebrew/bin` on Apple Silicon). An agent running inside a container does not automatically have Docker access. Prefer an agent configured by your lab administrator; do not blindly grant broad socket permissions.
3. Create an empty remote repository in your Git hosting browser. Add its URL with `git remote add origin YOUR_REPOSITORY_URL`, then `git push -u origin main` and `git push origin release-v6.0 v6.0.0-release`. These publish the project; review it first. No remote was created here.
4. Jenkins → New Item → Pipeline → name `iot-gateway` → OK. Pipeline → Definition: **Pipeline script from SCM** → SCM: Git → repository URL → credentials via Jenkins Credentials if needed → branch `*/main` → Script Path `Jenkinsfile` → Save.
5. Build Now → Console Output. Expect checkout, `IoT configuration verified`, successful Docker image build, and `IoT verification and image packaging completed`. Image exists on the agent's Docker host.
6. A failure in any stage should identify missing config, incorrect port, missing Docker CLI, or unreachable daemon. Use your Jenkins Declarative linter if available; actual job execution is the final syntax/runtime validation.

References: [Declarative syntax](https://www.jenkins.io/doc/book/pipeline/syntax/) and [SCM pipeline configuration](https://www.jenkins.io/doc/book/pipeline/getting-started/).

## D. Docker — real HTTP and continuous logs

The Dockerfile starts from Alpine and installs Python. `server.py` binds port 80, returns `Smart Hub Online` to GET requests, logs requests, and prints that message every five seconds. Alpine/Python work natively on Apple Silicon; no `--platform linux/amd64` emulation is needed.

Start Docker Desktop from Applications and wait for its engine. If absent, use the [Apple Silicon installer](https://docs.docker.com/desktop/setup/install/mac-install/), or choose to run `brew install --cask docker`. Installation and first launch require your interaction.

```bash
docker info
./scripts/run_docker.sh
# Equivalent fresh-run build/run:
docker build -t iot-hub:latest .
docker run -d --name iot-hub --label lab.project=iot-gateway -p 127.0.0.1:8088:80 iot-hub:latest
# Checks:
docker image inspect iot-hub:latest
docker ps --filter name=iot-hub
docker logs iot-hub
curl --fail http://localhost:8088
```

Expected HTTP body and periodic logs: `Smart Hub Online`. Mapping binds localhost for a local practical; `8088:80` without the localhost prefix exposes it on all host interfaces. The script reuses its own same-image container, refuses a conflicting unrelated name or stale image, and never deletes containers. For an intentional rebuild when a prior container uses an old image, preserve it and run with a different name/host port; update verification accordingly. A port-allocation error means another process uses 8088: inspect `lsof -nP -iTCP:8088 -sTCP:LISTEN`; do not kill arbitrary processes. A socket error means Docker Desktop is stopped or the Docker context is wrong (`docker context ls`).

## E. Kubernetes — nginx, two replicas

Manifest selectors and pod labels both use only `service: iot-core`. Deployment `iot-core` runs two `nginx:alpine` pods. Service `iot-core` maps port 80 to pod port 80 with NodePort 30098. This serves nginx's welcome page, independently of the Docker image above.

Choose a local lab cluster explicitly. For example, enable Kubernetes in Docker Desktop Settings → Kubernetes and wait for readiness. This changes local system resources and may download images. Do not select an unfamiliar remote cluster.

```bash
kubectl config get-contexts
kubectl config use-context docker-desktop  # only if this context exists and is intended
kubectl config current-context
kubectl cluster-info --request-timeout=5s
./scripts/run_kubernetes.sh             # checks cluster only
./scripts/run_kubernetes.sh --apply     # creates/updates in current namespace
kubectl rollout status deployment/iot-core --timeout=120s
kubectl get deployment iot-core
kubectl get pods -l service=iot-core --show-labels
kubectl get service iot-core -o wide
curl --fail --max-time 5 http://localhost:30098
```

Expected: deployment READY `2/2`, two Running pods labeled `service=iot-core`, service `NodePort` with `80:30098/TCP`. Direct manual apply is `kubectl apply -f k8s/`; use the script to retain its existing-resource safety check. The script annotates ownership without adding misleading pod labels. Pre-existing unowned resources cause refusal. Always inspect context/namespace; apply is a mutation. Access restrictions or an API timeout are errors, not proof that resource names are free.

NodePort routing differs by local cluster. On a VM/container-based cluster, localhost:30098 may not route. For minikube use `minikube service iot-core --url` (keep its terminal open when required), then curl the supplied URL. Portable fallback:

```bash
kubectl port-forward service/iot-core 8089:80
# In a second terminal:
curl --fail http://localhost:8089
```

Expected HTML includes `Welcome to nginx!`. Port-forward verifies service-backed HTTP but does not prove direct NodePort reachability. Ctrl-C stops only your port-forward process. For Pending pods inspect `kubectl describe pod POD_NAME`; for ImagePullBackOff check registry connectivity; for readiness issues use `kubectl logs POD_NAME` and `kubectl get events --sort-by=.lastTimestamp`. No resources are automatically deleted.

## F. Terraform and Ansible — one local file

Terraform uses only `hashicorp/local` and `local_file`; no cloud provider or cloud credentials are involved. `terraform/iot_config.env` will contain exactly:

```text
PORT=1883
BROKER=MQTT
```

State and plans can contain resource data. They and the generated file are ignored by Git; commit the provider lockfile after initialization for reproducibility. These lab values are non-secret. Never add credentials to the configuration.

Missing-tool installation, when you choose to install:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install ansible
terraform version
ansible --version
```

Run `./scripts/run_terraform_ansible.sh`. It initializes/downloads the provider, validates, saves and displays a plan, and prompts before applying. Read the plan: it should affect only the local file resource. Type `yes` only after review. Equivalent commands:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=lab.tfplan
terraform -chdir=terraform show -no-color lab.tfplan
# Only after reviewing the exact saved plan:
terraform -chdir=terraform apply lab.tfplan
printf 'PORT=1883\nBROKER=MQTT\n' | cmp - terraform/iot_config.env
command -v ansible
ansible localhost -i 'localhost,' -c local -m ansible.builtin.command -a "cat $(pwd)/terraform/iot_config.env"
```

Ansible expected: `localhost | CHANGED | rc=0` followed by the two values. The command module reports CHANGED by default even though `cat` only reads. A trailing comma makes `localhost,` an inline inventory; `-c local` avoids SSH. The file is read on the controller Mac. Python discovery warnings can be addressed with `-e "ansible_python_interpreter=$(command -v python3)"`. Download failures require network access; rerun init once restored. Terraform lock conflicts should be investigated, not bypassed by deleting locks blindly.

## Verification and evidence

```bash
./scripts/verify_all.sh
```

This checks available prerequisites and live resources without building, applying, starting services, changing Jira, or completing sprints. It exits nonzero for failed checks; unavailable prerequisites are SKIP. It cannot validate an uninitialized Terraform provider or execute a Jenkins job. Kubernetes HTTP may need the manual fallback above. See `VALIDATION.md` for actual checks performed during creation; expected outputs elsewhere in this document are guidance, not execution evidence.

## Viva revision

| Question | Short answer |
|---|---|
| Branch versus tag? | A branch moves with new commits; a tag marks a specific release commit. |
| What is a fast-forward merge? | Git moves the destination branch to a descendant commit without a merge commit. |
| Why create main first? | An unborn branch has no commit; a scaffold commit makes main exist before branching. |
| What does Jenkins checkout scm do? | Fetches the repository/revision configured in the Pipeline job. |
| Image versus container? | An image is a packaged template; a container is a running instance. |
| What does 8088:80 mean? | Host TCP port 8088 forwards to container TCP port 80. |
| Why is EXPOSE insufficient? | It documents a port; a process must listen and runtime publishing must be configured. |
| Deployment versus Service? | Deployment manages replicated pods; Service routes to selected ready pods. |
| How does the selector work? | The service matches pod labels; mismatches produce no usable endpoints. |
| What is NodePort? | A service exposes a fixed port on cluster nodes, subject to local network routing. |
| Terraform versus Ansible? | Terraform declares resources and tracks state; Ansible runs configuration/operational tasks. |
| What is idempotence? | Repeating an operation converges to the same desired state. |
| What does burndown show? | Remaining sprint work over time, with scope and estimate changes affecting its shape. |

## Exam-ready command cheat sheet

```bash
# A — already initialized? Inspect first; do not re-create commits/tags.
./scripts/run_git.sh
git branch -v
git log --oneline --decorate --all
git tag -n
# B — Jira browser: inspect IOT-10/IOT-20 → approval → Done;
# inspect Sprint-IoT-Ingest → approval → Complete sprint → Reports/Burndown.
# C — Jenkins browser: Pipeline script from SCM → main → Jenkinsfile → Build Now.
# D
./scripts/run_docker.sh
curl --fail http://localhost:8088
# E — inspect context first
kubectl config current-context
./scripts/run_kubernetes.sh --apply
kubectl get pods -l service=iot-core --show-labels
kubectl get svc iot-core
# F — inspect saved plan, then confirm prompt
./scripts/run_terraform_ansible.sh
# All tasks (read-only checks)
./scripts/verify_all.sh
```
