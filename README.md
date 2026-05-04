# hello-my-oc

Run [OpenClaw](https://docs.openclaw.ai/) on a single AWS EC2 instance with Terraform and Docker Compose.

This is a small infrastructure project for personal use and portfolio review. It keeps the architecture intentionally simple: one production environment, one EC2 host, restricted SSH access, and no public OpenClaw dashboard port.

## Quick Start

### 0. Prerequisites

- AWS CLI credentials configured for the target account.
- Terraform `>= 1.5`.
- Existing EC2 key pair in the target AWS region.
- Your current public IPv4 CIDR, for example `203.0.113.10/32`.

```bash
export AWS_PROFILE=your-profile
export AWS_REGION=ap-northeast-2
```

### 1. Bootstrap Terraform State

```bash
cp infra/terraform/bootstrap/terraform.tfvars.example infra/terraform/bootstrap/terraform.tfvars
vi infra/terraform/bootstrap/terraform.tfvars
./scripts/bootstrap_state.sh
```

Set at least:

```hcl
state_bucket_name = "globally-unique-bucket-name"
lock_table_name   = "hello-my-oc-tf-lock"
```

This creates:

- S3 bucket for Terraform state.
- DynamoDB table for state locking.
- `infra/terraform/live/production/backend.hcl`.

### 2. Provision EC2 Infrastructure

```bash
cp infra/terraform/live/production/terraform.tfvars.example infra/terraform/live/production/terraform.tfvars
vi infra/terraform/live/production/terraform.tfvars
make plan AWS_PROFILE=your-profile AWS_REGION=ap-northeast-2
make create AWS_PROFILE=your-profile AWS_REGION=ap-northeast-2
```

Minimum variables to check:

```hcl
key_name                    = "your-ec2-keypair-name"
ssh_ingress_cidr            = "203.0.113.10/32"
associate_public_ip_address = true
enable_ssm_vpc_endpoints    = false
```

### 3. Deploy OpenClaw

Register the host key, then deploy:

```bash
PUBLIC_IP="$(terraform -chdir=infra/terraform/live/production output -raw public_ip)"
ssh-keyscan -H "$PUBLIC_IP" >> ~/.ssh/known_hosts
TOKEN="$(openssl rand -hex 32)"
OPENCLAW_GATEWAY_TOKEN="$TOKEN" ./scripts/deploy_openclaw.sh --key /path/to/key.pem
```

If `OPENCLAW_GATEWAY_TOKEN` is not set, the deploy script prompts for it without echoing input.

### 4. Open The Dashboard

```bash
PUBLIC_IP="$(terraform -chdir=infra/terraform/live/production output -raw public_ip)"
ssh -fN -L 18789:127.0.0.1:18789 -i /path/to/key.pem ubuntu@"$PUBLIC_IP"
open http://127.0.0.1:18789
```

Enter the gateway token in the dashboard settings when prompted.

### 5. Add Integrations

Runtime integrations live in `/opt/openclaw/.env` on the EC2 instance, not in Terraform state.

```bash
ssh -i /path/to/key.pem ubuntu@"$PUBLIC_IP"
cd /opt/openclaw
vi .env
docker compose up -d
```

Example values:

```dotenv
TELEGRAM_BOT_TOKEN=replace-me
OPENAI_API_KEY=replace-me
```

Use [deploy/compose/.env.example](deploy/compose/.env.example) as the template.

## What This Builds

- AWS VPC with one public subnet, internet gateway, and route table.
- EC2 instance for OpenClaw, currently tuned for `t4g.small`.
- Encrypted `gp3` root volume.
- Security group with SSH restricted to one operator CIDR.
- IAM role includes the SSM managed policy; private SSM access remains optional.
- Optional SSM VPC endpoints, disabled by default to avoid fixed monthly cost.
- CloudWatch alarms for instance health, CPU, and burstable CPU credits.
- Docker and Docker Compose v2 installed by cloud-init.
- OpenClaw gateway deployed by Docker Compose.

## Architecture

```text
Local browser
  -> http://127.0.0.1:18789
  -> SSH tunnel
  -> EC2 localhost:18789
  -> OpenClaw gateway container
  -> Telegram / LLM provider integrations
```

OpenClaw is not exposed directly to the public internet. The dashboard is accessed through local port forwarding.

## Repository Layout

```text
.
├── deploy/
│   ├── cloud-init/          # EC2 bootstrap for Docker
│   └── compose/             # OpenClaw Docker Compose template
├── docs/
│   ├── adr/                 # Architecture decision records
│   ├── architecture.md
│   ├── decisions.md
│   └── requirements.md
├── infra/terraform/
│   ├── bootstrap/           # S3 + DynamoDB Terraform state backend
│   ├── live/production/     # Single production environment
│   └── modules/             # Network, EC2, observability modules
├── scripts/                 # Bootstrap, plan, apply, deploy helpers
└── Makefile
```

## Key Configuration

Production variables live in `infra/terraform/live/production/terraform.tfvars`.

| Variable | Default | Notes |
| --- | --- | --- |
| `instance_type` | `t4g.small` | Low-cost ARM baseline with 2 GB memory. |
| `volume_size_gb` | `20` | Encrypted `gp3` root volume. |
| `key_name` | `""` | Existing EC2 key pair name. Required for SSH mode. |
| `ssh_ingress_cidr` | `""` | Operator CIDR allowed for SSH. |
| `enable_ssm_vpc_endpoints` | `false` | Keep disabled for minimum cost. |
| `alarm_sns_topic_arn` | `""` | Optional CloudWatch notification target. |

## Telegram Integration

1. Create a bot with Telegram `@BotFather`.
2. Add `TELEGRAM_BOT_TOKEN` to `/opt/openclaw/.env`.
3. Restart OpenClaw with `docker compose up -d`.
4. Send `/start` to the bot.
5. Approve pairing through the OpenClaw CLI if required.

```bash
cd /opt/openclaw
docker compose run --rm openclaw-cli pairing list telegram
docker compose run --rm openclaw-cli pairing approve telegram <code>
```

## Operations

```bash
# Resolve the current EC2 public IP in a new shell.
PUBLIC_IP="$(terraform -chdir=infra/terraform/live/production output -raw public_ip)"

# Terraform outputs
terraform -chdir=infra/terraform/live/production output

# Create or update the production EC2 stack
make create AWS_PROFILE=your-profile AWS_REGION=ap-northeast-2

# OpenClaw container status
ssh -i /path/to/key.pem ubuntu@"$PUBLIC_IP" 'cd /opt/openclaw && docker compose ps'

# Gateway logs
ssh -i /path/to/key.pem ubuntu@"$PUBLIC_IP" 'docker logs --tail=200 openclaw-gateway'

# Restart OpenClaw
ssh -i /path/to/key.pem ubuntu@"$PUBLIC_IP" 'cd /opt/openclaw && docker compose up -d'
```

If the dashboard reports `device token mismatch`, clear site data for `127.0.0.1:18789`, restart the tunnel, and enter the current gateway token again.

## Teardown

Destroy the production EC2 stack:

```bash
make destroy AWS_PROFILE=your-profile AWS_REGION=ap-northeast-2
```

This removes the OpenClaw runtime infrastructure managed by `infra/terraform/live/production`, including EC2, networking, IAM attachment/profile resources, and CloudWatch alarms.

The Terraform state backend is intentionally not destroyed by this command. The S3 state bucket and DynamoDB lock table are protected with `prevent_destroy` because deleting them can break state recovery.

## Security Notes

- Runtime secrets are not committed and are not managed by Terraform state.
- `backend.hcl`, `terraform.tfvars`, state files, and runtime `.env` files are ignored by git.
- The OpenClaw dashboard port is not opened in the EC2 security group.
- SSH is restricted by CIDR. Rotate `ssh_ingress_cidr` when your public IP changes.
- The gateway token should be generated with high entropy.
- Avoid pasting real secrets into shell history. Prefer interactive prompts or editing `/opt/openclaw/.env` directly on EC2.

## Validation

```bash
make fmt
make validate
./scripts/tf_preflight.sh
```

CI runs Terraform format and validation checks for the production stack on pull requests.

## Design Decisions

- [Architecture overview](docs/architecture.md)
- [Decision log](docs/decisions.md)
- [ADR 0001: Docker runtime](docs/adr/0001-runtime-docker.md)
- [ADR 0002: Restricted OpenClaw exposure](docs/adr/0002-network-private-first.md)

## References

- [OpenClaw Docker documentation](https://docs.openclaw.ai/install/docker)
- [OpenClaw Telegram channel documentation](https://docs.openclaw.ai/channels/telegram)
- [Terraform S3 backend documentation](https://developer.hashicorp.com/terraform/language/backend/s3)
