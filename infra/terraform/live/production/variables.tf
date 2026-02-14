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

variable "subnet_id" {
  description = "Subnet ID for EC2 placement. Empty means auto-select."
  type        = string
  default     = ""

  validation {
    condition     = var.subnet_id == "" || can(regex("^subnet-[a-z0-9]+$", var.subnet_id))
    error_message = "subnet_id must be empty or a valid subnet ID like subnet-abc12345."
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
