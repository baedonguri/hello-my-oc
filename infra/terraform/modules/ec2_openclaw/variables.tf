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
  description = "Subnet ID to launch the EC2 instance into."
  type        = string
}

variable "enable_ssm_vpc_endpoints" {
  description = "Create interface VPC endpoints for SSM in private subnet mode."
  type        = bool
  default     = false
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address with the instance."
  type        = bool
  default     = true
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Empty means no key pair."
  type        = string
  default     = ""
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to access SSH (22/tcp). Empty means SSH ingress is disabled."
  type        = string
  default     = ""
}

variable "cloud_init_user_data" {
  description = "Cloud-init user_data content applied at instance launch."
  type        = string
  default     = ""
}
