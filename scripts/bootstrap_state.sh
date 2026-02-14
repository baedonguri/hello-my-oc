#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/infra/terraform/bootstrap"
TFVARS_FILE="$BOOTSTRAP_DIR/terraform.tfvars"

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "missing $TFVARS_FILE"
  echo "copy from terraform.tfvars.example and fill values first"
  exit 1
fi

cd "$BOOTSTRAP_DIR"
terraform init
terraform apply

cd "$ROOT_DIR"
./scripts/render_backend_hcl.sh
