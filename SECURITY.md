# Security Policy

## Supported Use

This repository is a personal infrastructure project for running OpenClaw on AWS EC2. It is shared publicly for learning and reference.

## Reporting a Vulnerability

If you find a security issue, please open a GitHub issue with a minimal description and avoid posting real credentials, tokens, private keys, IP allowlists, or Terraform state.

For sensitive details, contact the maintainer directly through the GitHub profile associated with this repository.

## Secret Handling

- Do not commit real `.env`, `terraform.tfvars`, `backend.hcl`, Terraform state, SSH private keys, or provider tokens.
- Rotate any credential that may have been exposed in local shell history, logs, screenshots, or public commits.
- Keep OpenClaw access behind the SSH tunnel unless you intentionally add a hardened public HTTPS entrypoint.
