terraform {
  required_version = ">= 1.5.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  instance_family       = split(".", var.instance_type)[0]
  is_burstable_instance = startswith(local.instance_family, "t")
}

module "ec2_openclaw" {
  source = "../../modules/ec2_openclaw"

  project_name   = var.project_name
  environment    = var.environment
  instance_type  = var.instance_type
  volume_size_gb = var.volume_size_gb
}

module "observability" {
  source = "../../modules/observability"

  project_name             = var.project_name
  environment              = var.environment
  instance_id              = module.ec2_openclaw.instance_id
  enable_cpu_credit_alarm  = local.is_burstable_instance
  cpu_high_threshold       = var.cpu_high_threshold
  cpu_credit_low_threshold = var.cpu_credit_low_threshold
}

output "instance_id" {
  value = module.ec2_openclaw.instance_id
}

output "ssm_target" {
  value = module.ec2_openclaw.instance_id
}

output "alarm_names" {
  value = module.observability.alarm_names
}
