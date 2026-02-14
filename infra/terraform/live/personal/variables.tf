variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hello-my-oc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "personal"
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
}

variable "volume_size_gb" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "cpu_high_threshold" {
  description = "CloudWatch alarm threshold for high CPU utilization (%)"
  type        = number
  default     = 80
}

variable "cpu_credit_low_threshold" {
  description = "CloudWatch alarm threshold for low CPU credit balance"
  type        = number
  default     = 20
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications. Empty means disabled."
  type        = string
  default     = ""
}
