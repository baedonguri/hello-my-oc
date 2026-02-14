variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hello-my-oc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.small"

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must be in a valid EC2 format like t4g.small."
  }
}

variable "volume_size_gb" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.volume_size_gb >= 8 && var.volume_size_gb <= 200
    error_message = "volume_size_gb must be between 8 and 200."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet."
  type        = string
  default     = "10.42.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid CIDR block."
  }
}

variable "availability_zone" {
  description = "Availability zone for the public subnet. Empty picks first available."
  type        = string
  default     = ""

  validation {
    condition     = var.availability_zone == "" || can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone))
    error_message = "availability_zone must be empty or a valid zone like ap-northeast-2a."
  }
}

variable "enable_ssm_vpc_endpoints" {
  description = "Create VPC interface endpoints for SSM connectivity without public IP."
  type        = bool
  default     = false
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IPv4 address to the EC2 instance."
  type        = bool
  default     = true
}

variable "key_name" {
  description = "EC2 key pair name used for SSH access."
  type        = string
  default     = ""

  validation {
    condition     = var.key_name == "" || can(regex("^[A-Za-z0-9._-]+$", var.key_name))
    error_message = "key_name must be empty or a valid EC2 key pair name."
  }
}

variable "ssh_ingress_cidr" {
  description = "Operator CIDR allowed for SSH (22/tcp), e.g. 203.0.113.10/32."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_ingress_cidr == "" || can(cidrnetmask(var.ssh_ingress_cidr))
    error_message = "ssh_ingress_cidr must be empty or a valid CIDR block."
  }
}

variable "cpu_high_threshold" {
  description = "CloudWatch alarm threshold for high CPU utilization (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_high_threshold >= 50 && var.cpu_high_threshold <= 95
    error_message = "cpu_high_threshold must be between 50 and 95."
  }
}

variable "cpu_credit_low_threshold" {
  description = "CloudWatch alarm threshold for low CPU credit balance"
  type        = number
  default     = 20

  validation {
    condition     = var.cpu_credit_low_threshold >= 1 && var.cpu_credit_low_threshold <= 100
    error_message = "cpu_credit_low_threshold must be between 1 and 100."
  }
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications. Empty means disabled."
  type        = string
  default     = ""

  validation {
    condition = (
      var.alarm_sns_topic_arn == "" ||
      can(regex("^arn:aws(-[a-z]+)?:sns:[a-z0-9-]+:[0-9]{12}:.+$", var.alarm_sns_topic_arn))
    )
    error_message = "alarm_sns_topic_arn must be empty or a valid SNS topic ARN."
  }
}
