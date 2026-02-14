variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "volume_size_gb" {
  type = number
}

variable "subnet_id" {
  description = "Subnet ID to launch the EC2 instance into. Empty means auto-select."
  type        = string
  default     = ""
}
