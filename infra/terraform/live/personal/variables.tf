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
