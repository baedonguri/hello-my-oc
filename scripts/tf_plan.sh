#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/personal"
BACKEND_FILE="$LIVE_DIR/backend.hcl"

if [[ ! -f "$BACKEND_FILE" ]]; then
  echo "missing $BACKEND_FILE"
  echo "run ./scripts/bootstrap_state.sh first"
  exit 1
fi

cd "$LIVE_DIR"
terraform init -backend-config=backend.hcl
terraform plan
