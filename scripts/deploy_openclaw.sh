#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/infra/terraform/live/production"
COMPOSE_FILE="$ROOT_DIR/deploy/compose/docker-compose.yml"

KEY_PATH="${KEY_PATH:-}"
TARGET_IP="${TARGET_IP:-}"
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-${OPENCLAW_AUTH_TOKEN:-}}"
OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:2026.2.13}"
KNOWN_HOSTS_PATH="${KNOWN_HOSTS_PATH:-$HOME/.ssh/known_hosts}"

usage() {
  cat <<'EOF'
usage: scripts/deploy_openclaw.sh --key <pem-path> [--ip <public-ip>] [--image <image>]

Examples:
  OPENCLAW_GATEWAY_TOKEN=xxx scripts/deploy_openclaw.sh --key ~/.ssh/oh-my-oc-key.pem
  scripts/deploy_openclaw.sh --key ~/.ssh/oh-my-oc-key.pem --ip 1.2.3.4
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

if [[ -z "$TARGET_IP" ]]; then
  TARGET_IP="$(terraform -chdir="$LIVE_DIR" output -raw public_ip)"
fi

if [[ -z "$TARGET_IP" ]]; then
  echo "failed to resolve target ip" >&2
  exit 1
fi

if [[ -z "$OPENCLAW_GATEWAY_TOKEN" ]]; then
  read -r -s -p "Enter OPENCLAW_GATEWAY_TOKEN: " OPENCLAW_GATEWAY_TOKEN
  echo
fi

if [[ -z "$OPENCLAW_GATEWAY_TOKEN" ]]; then
  echo "OPENCLAW_GATEWAY_TOKEN is required" >&2
  exit 1
fi

if [[ "$OPENCLAW_GATEWAY_TOKEN" =~ [[:space:]] ]]; then
  echo "OPENCLAW_GATEWAY_TOKEN must not contain whitespace" >&2
  exit 1
fi

if [[ ! -f "$KNOWN_HOSTS_PATH" ]]; then
  echo "known_hosts file not found: $KNOWN_HOSTS_PATH" >&2
  echo "Run: ssh-keyscan -H $TARGET_IP >> $KNOWN_HOSTS_PATH" >&2
  exit 1
fi

if ! ssh-keygen -F "$TARGET_IP" -f "$KNOWN_HOSTS_PATH" >/dev/null; then
  echo "Host key for $TARGET_IP is not registered in $KNOWN_HOSTS_PATH" >&2
  echo "Run: ssh-keyscan -H $TARGET_IP >> $KNOWN_HOSTS_PATH" >&2
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

SSH_OPTS=(-i "$KEY_PATH" -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KNOWN_HOSTS_PATH")

ssh "${SSH_OPTS[@]}" "ubuntu@$TARGET_IP" "sudo mkdir -p /opt/openclaw/data && sudo chown -R ubuntu:ubuntu /opt/openclaw && sudo chown -R 1000:1000 /opt/openclaw/data"
scp "${SSH_OPTS[@]}" "$COMPOSE_FILE" "ubuntu@$TARGET_IP:/opt/openclaw/docker-compose.yml"
scp "${SSH_OPTS[@]}" "$TMP_ENV" "ubuntu@$TARGET_IP:/tmp/openclaw.env.deploy"

ssh "${SSH_OPTS[@]}" "ubuntu@$TARGET_IP" '
  set -euo pipefail
  cd /opt/openclaw

  touch .env
  merge_env_var() {
    key="$1"
    value="$2"
    file="$3"
    tmp="$(mktemp)"

    if grep -q "^${key}=" "$file"; then
      awk -v k="$key" -v v="$value" '"'"'BEGIN { FS = "=" } $1 == k { print k "=" v; next } { print }'"'"' "$file" > "$tmp"
    else
      cp "$file" "$tmp"
      printf "%s=%s\n" "$key" "$value" >> "$tmp"
    fi

    mv "$tmp" "$file"
  }

  image_value="$(sed -n "s/^OPENCLAW_IMAGE=//p" /tmp/openclaw.env.deploy | tail -n 1)"
  gateway_token_value="$(sed -n "s/^OPENCLAW_GATEWAY_TOKEN=//p" /tmp/openclaw.env.deploy | tail -n 1)"

  merge_env_var "OPENCLAW_IMAGE" "$image_value" .env
  merge_env_var "OPENCLAW_GATEWAY_TOKEN" "$gateway_token_value" .env
  merge_env_var "OPENCLAW_AUTH_TOKEN" "$gateway_token_value" .env
  merge_env_var "OPENCLAW_PORT" "18789" .env
  rm -f /tmp/openclaw.env.deploy

  if ! docker compose version >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-v2 || sudo apt-get install -y docker-compose-plugin
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose is not installed" >&2
    exit 1
  fi

  # Remove an existing standalone container with the same fixed name.
  docker rm -f openclaw-gateway >/dev/null 2>&1 || true

  # Clean up legacy v1 containers that can conflict with the fixed container_name.
  docker ps -a --format "{{.Names}}" | grep -E "openclaw-gateway$" | grep -v "^openclaw-gateway$" | xargs -r docker rm -f

  docker compose down --remove-orphans || true
  docker compose pull
  docker compose up -d
  docker compose ps
'

echo "OpenClaw deployed on $TARGET_IP"
echo "Open the dashboard through an SSH tunnel: ssh -fN -L 18789:127.0.0.1:18789 -i <key> ubuntu@$TARGET_IP"
echo "Run CLI commands on EC2 with: cd /opt/openclaw && docker compose run --rm openclaw-cli <command>"
