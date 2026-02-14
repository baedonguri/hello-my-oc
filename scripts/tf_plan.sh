#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../infra/terraform/live/personal"
terraform init -backend-config=backend.hcl
terraform plan
