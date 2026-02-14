#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/production"
"$ROOT_DIR/scripts/tf_preflight.sh"

cd "$LIVE_DIR"
terraform init -backend-config=backend.hcl
terraform apply
