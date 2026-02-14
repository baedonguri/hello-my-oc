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
  cloud_init_user_data  = file("${path.module}/../../../../deploy/cloud-init/openclaw.yaml")
}

module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "ec2_openclaw" {
  source = "../../modules/ec2_openclaw"

  project_name                = var.project_name
  environment                 = var.environment
  instance_type               = var.instance_type
  volume_size_gb              = var.volume_size_gb
  subnet_id                   = module.network.public_subnet_id
  enable_ssm_vpc_endpoints    = var.enable_ssm_vpc_endpoints
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  ssh_ingress_cidr            = var.ssh_ingress_cidr
  cloud_init_user_data        = local.cloud_init_user_data
}

module "observability" {
  source = "../../modules/observability"

  project_name             = var.project_name
  environment              = var.environment
  instance_id              = module.ec2_openclaw.instance_id
  enable_cpu_credit_alarm  = local.is_burstable_instance
  cpu_high_threshold       = var.cpu_high_threshold
  cpu_credit_low_threshold = var.cpu_credit_low_threshold
  alarm_sns_topic_arn      = var.alarm_sns_topic_arn
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

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "public_ip" {
  value = module.ec2_openclaw.public_ip
}
