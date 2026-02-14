# ADR 0002: Private-First Network Posture

- Date: 2026-02-14
- Status: Accepted

## Context

OpenClaw can execute privileged actions and should not be publicly exposed by default. The project is personal-use and cost constrained.

## Decision

Operate EC2 in private-first mode:

- No public OpenClaw service port exposure.
- Management access via AWS SSM Session Manager.
- Public ingress is deferred to a later explicit phase.

## Consequences

### Positive

- Lower attack surface.
- Simpler first production baseline.
- No immediate TLS reverse-proxy setup required.

### Negative

- Webhook-style integrations may require later architecture changes.
- Remote access UX is less direct than public HTTPS endpoint.

## Follow-up

- Create IAM role/policies for SSM access.
- Keep security group inbound rules minimal or empty.
- Document how to migrate to public HTTPS safely later.

