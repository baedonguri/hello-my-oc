terraform {
  required_version = ">= 1.5.0"

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

module "ec2_openclaw" {
  source = "../../modules/ec2_openclaw"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  instance_type  = var.instance_type
  volume_size_gb = var.volume_size_gb
}

output "instance_id" {
  value = module.ec2_openclaw.instance_id
}

output "ssm_target" {
  value = module.ec2_openclaw.instance_id
}
