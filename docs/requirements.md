# Requirements

Last updated: 2026-02-14

## Functional

- Run OpenClaw Gateway on AWS EC2 for personal use.
- Use Docker as runtime.
- Manage infrastructure with Terraform (IaC).
- Support future Telegram and Discord bot integrations.

## Non-Functional

- Budget target: up to 15 USD/month.
- Single environment only (`personal`).
- Repository should be publicly shareable as portfolio.
- Default network posture should be private-first.

## Operational Constraints

- Minimize inbound exposure.
- Keep secrets out of git.
- Prefer reproducible deployment from clean machine.

