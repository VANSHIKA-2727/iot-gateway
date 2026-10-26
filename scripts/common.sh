#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
need() { command -v "$1" >/dev/null || { echo "ERROR: $1 is missing; see README.md" >&2; exit 1; }; }
step() { printf '\n[%s] %s\n' "$1" "$2"; }
