#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../infra/terraform/bootstrap"
terraform init
terraform apply
