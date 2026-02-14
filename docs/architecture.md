# Architecture Overview (Step 1 Baseline)

Last updated: 2026-02-14

## Scope

Single EC2 host running OpenClaw via Docker Compose.

## High-Level Components

1. Terraform: provisions AWS infrastructure.
2. EC2: runs Docker and OpenClaw containers.
3. SSM Parameter Store: stores runtime secrets.
4. CloudWatch: logs and baseline alarms.

## Access Model

- Default: private-first.
- Management: AWS SSM Session Manager.
- Public ingress: not enabled in initial phase.

## Cost Guardrails

- Instance target: `t3.micro`.
- Storage target: `gp3 20GB`.
- Avoid NAT Gateway unless explicitly required.

