# hello-my-oc

Personal infrastructure repo for running OpenClaw on AWS EC2 using Terraform and Docker.

## Current Status

- Step 1 complete: architecture decisions documented.
- Step 2 complete: repository scaffold and Terraform baseline created.

## Repository Layout

- `infra/terraform/bootstrap`: Terraform state backend (S3 + DynamoDB lock).
- `infra/terraform/live/personal`: single environment stack.
- `infra/terraform/modules/ec2_openclaw`: EC2 baseline module.
- `deploy/compose`: Docker Compose templates.
- `deploy/cloud-init`: EC2 bootstrap templates.
- `scripts`: helper scripts for init/plan/apply/smoke tests.
- `docs`: requirements, ADRs, architecture notes.

## Next Step

Implement and wire remote backend usage, then provision core infra in AWS.
