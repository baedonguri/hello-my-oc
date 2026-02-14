# ADR 0001: Use Docker Runtime for OpenClaw

- Date: 2026-02-14
- Status: Accepted

## Context

The project goals include learning Docker and producing a portfolio-ready repository. The deployment target is a single EC2 instance for personal use.

## Decision

Use Docker (with Docker Compose) as the OpenClaw runtime on EC2.

## Consequences

### Positive

- Aligns directly with learning goals.
- Reproducible runtime definition in version control.
- Easier service restart and update flow than ad-hoc host installs.

### Negative

- Adds Docker-specific operational surface.
- Requires image/version pinning policy to avoid drift.

## Follow-up

- Define `docker-compose.yml` and `.env.example`.
- Add container healthcheck and restart policy.

