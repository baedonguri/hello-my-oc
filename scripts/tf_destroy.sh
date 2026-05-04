#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/production"
BACKEND_FILE="$LIVE_DIR/backend.hcl"
CONFIRM_VALUE="destroy hello-my-oc production"

"$ROOT_DIR/scripts/tf_preflight.sh"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is not installed" >&2
  exit 1
fi

backend_bucket="$(awk -F'"' '/^[[:space:]]*bucket[[:space:]]*=/{ print $2 }' "$BACKEND_FILE")"
backend_region="$(awk -F'"' '/^[[:space:]]*region[[:space:]]*=/{ print $2 }' "$BACKEND_FILE")"

if [[ -z "$backend_bucket" || -z "$backend_region" ]]; then
  echo "failed to parse bucket or region from $BACKEND_FILE" >&2
  exit 1
fi

echo "Using AWS_PROFILE=${AWS_PROFILE:-<default>}"
echo "Using AWS_REGION=${AWS_REGION:-${AWS_DEFAULT_REGION:-$backend_region}}"
if ! aws sts get-caller-identity >/dev/null; then
  echo "failed to resolve AWS credentials. Set AWS_PROFILE/AWS_REGION and try again." >&2
  exit 1
fi

if ! aws s3api head-bucket --bucket "$backend_bucket" --region "$backend_region" >/dev/null; then
  echo "failed to access Terraform state bucket: $backend_bucket" >&2
  echo "check that the selected AWS profile owns or can read the backend bucket." >&2
  exit 1
fi

cd "$LIVE_DIR"
terraform init -backend-config=backend.hcl
terraform plan -destroy

if [[ "${AUTO_APPROVE:-}" == "true" ]]; then
  terraform destroy -auto-approve
  exit 0
fi

echo
echo "This will destroy the production OpenClaw infrastructure managed by Terraform."
echo "Terraform state backend resources are not destroyed by this script."
echo "Type '${CONFIRM_VALUE}' to continue:"
read -r confirmation

if [[ "$confirmation" != "$CONFIRM_VALUE" ]]; then
  echo "destroy cancelled"
  exit 1
fi

terraform destroy
