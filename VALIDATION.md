# Actual validation — 26 October 2026

- Environment: macOS Darwin, Apple Silicon arm64.
- `setup.sh`: ran successfully; Git, Python, Docker CLI and kubectl found. Terraform and Ansible missing.
- `bash -n`: all eight shell scripts passed.
- Python AST parse: passed for docker/server.py.
- Real loopback HTTP test: passed GET /, status 200, exact body `Smart Hub Online\n`, Content-Type, and observed request log. The ephemeral test server was closed afterward. Initial sandbox binding was denied; the same test succeeded with approved execution permissions.
- Both Kubernetes YAML files parsed successfully using Ruby YAML. Parsed structure checked for replicas, image, labels/selectors, ports and NodePort. This is not Kubernetes API/schema validation.
- Git: repository initialized on main; MQTT committed on release-v6.0, fast-forwarded into main; annotated v6.0.0-release created. Final local release incorporates safety/documentation checks. No remote configured or pushed.
- Docker: daemon socket unavailable. No image built, container started, port-8088 HTTP or container logs verified. Local HTTP test is not a Docker test.
- Kubernetes: no current context; no deployment applied. No live readiness, pod, service or NodePort result claimed.
- Terraform: absent, so no native fmt/validate/init/plan/apply run and no generated iot_config.env.
- Ansible: absent; ad-hoc command not executed.
- Jenkins: CLI absent and default localhost:8080 unreachable. Remote Jenkins availability unknown. Jenkinsfile reviewed structurally only; no Jenkins linter/build run.
- Jira: no approved connector exposed. No Jira credentials read, issues inspected/changed, sprint completed, or report viewed.
- `verify_all.sh`: run; available static and Git checks pass, unavailable live services skipped. SKIP is not success.

Next: start Docker Desktop; choose/enable a local cluster; install Terraform/Ansible when ready; review the local Terraform plan before confirming apply; configure Jenkins SCM and perform a build. Jira changes and sprint completion require explicit confirmation after inspection.
