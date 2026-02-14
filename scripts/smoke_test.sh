#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:-}"
if [[ -z "$INSTANCE_ID" ]]; then
  echo "usage: $0 <instance-id>"
  exit 1
fi

echo "Checking SSM instance status for $INSTANCE_ID"
aws ssm describe-instance-information \
  --query "InstanceInformationList[?InstanceId=='$INSTANCE_ID'].PingStatus" \
  --output text
