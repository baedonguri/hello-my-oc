#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/production"
COMPOSE_FILE="$ROOT_DIR/deploy/compose/docker-compose.yml"

KEY_PATH="${KEY_PATH:-}"
TARGET_IP="${TARGET_IP:-}"
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-${OPENCLAW_AUTH_TOKEN:-}}"
OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:2026.2.13}"

usage() {
  cat <<'EOF'
usage: scripts/deploy_openclaw.sh --key <pem-path> [--ip <public-ip>] [--token <gateway-token>] [--image <image>]

Examples:
  OPENCLAW_GATEWAY_TOKEN=xxx scripts/deploy_openclaw.sh --key ~/.ssh/oh-my-oc-key.pem
  scripts/deploy_openclaw.sh --key ~/.ssh/oh-my-oc-key.pem --ip 1.2.3.4 --token xxx
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)
      KEY_PATH="$2"
      shift 2
      ;;
    --ip)
      TARGET_IP="$2"
      shift 2
      ;;
    --token)
      OPENCLAW_GATEWAY_TOKEN="$2"
      shift 2
      ;;
    --image)
      OPENCLAW_IMAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$KEY_PATH" ]]; then
  echo "--key is required" >&2
  usage
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "key file not found: $KEY_PATH" >&2
  exit 1
fi

if [[ -z "$OPENCLAW_GATEWAY_TOKEN" ]]; then
  echo "OPENCLAW_GATEWAY_TOKEN is required (env var or --token)" >&2
  exit 1
fi

if [[ -z "$TARGET_IP" ]]; then
  TARGET_IP="$(terraform -chdir="$LIVE_DIR" output -raw public_ip)"
fi

if [[ -z "$TARGET_IP" ]]; then
  echo "failed to resolve target ip" >&2
  exit 1
fi

TMP_ENV="$(mktemp)"
trap 'rm -f "$TMP_ENV"' EXIT

cat > "$TMP_ENV" <<EOF
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_AUTH_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_PORT=18789
EOF

chmod 600 "$KEY_PATH"

SSH_OPTS=(-i "$KEY_PATH" -o StrictHostKeyChecking=accept-new)

ssh "${SSH_OPTS[@]}" "ubuntu@$TARGET_IP" "sudo mkdir -p /opt/openclaw && sudo chown ubuntu:ubuntu /opt/openclaw"
scp "${SSH_OPTS[@]}" "$COMPOSE_FILE" "ubuntu@$TARGET_IP:/opt/openclaw/docker-compose.yml"
scp "${SSH_OPTS[@]}" "$TMP_ENV" "ubuntu@$TARGET_IP:/opt/openclaw/.env"

ssh "${SSH_OPTS[@]}" "ubuntu@$TARGET_IP" '
  set -euo pipefail
  cd /opt/openclaw
  if ! docker compose version >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-v2 || sudo apt-get install -y docker-compose-plugin
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose is not installed" >&2
    exit 1
  fi

  # Clean up legacy v1 containers that can conflict with the fixed container_name.
  docker ps -a --format "{{.Names}}" | grep -E "openclaw-gateway$" | grep -v "^openclaw-gateway$" | xargs -r docker rm -f

  docker compose down --remove-orphans || true
  docker compose pull
  docker compose up -d
  docker compose ps
'

echo "OpenClaw deployed on $TARGET_IP"
