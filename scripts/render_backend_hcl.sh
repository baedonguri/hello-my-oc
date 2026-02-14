#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/infra/terraform/bootstrap"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/personal"
BACKEND_FILE="$LIVE_DIR/backend.hcl"

cd "$BOOTSTRAP_DIR"

bucket="$(terraform output -raw state_bucket_name 2>/dev/null || true)"
lock_table="$(terraform output -raw lock_table_name 2>/dev/null || true)"
region="$(terraform output -raw aws_region 2>/dev/null || true)"
project="$(terraform output -raw project_name 2>/dev/null || true)"
environment="$(terraform output -raw environment 2>/dev/null || true)"

if [[ -z "$bucket" || -z "$lock_table" || -z "$region" || -z "$project" || -z "$environment" ]]; then
  echo "bootstrap outputs are missing. run ./scripts/bootstrap_state.sh first."
  exit 1
fi

key="$project/$environment/terraform.tfstate"

cat > "$BACKEND_FILE" <<EOT
bucket         = "$bucket"
key            = "$key"
region         = "$region"
dynamodb_table = "$lock_table"
encrypt        = true
EOT

echo "wrote $BACKEND_FILE"
