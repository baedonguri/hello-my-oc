variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "enable_cpu_credit_alarm" {
  type    = bool
  default = true
}

variable "cpu_high_threshold" {
  type    = number
  default = 80
}

variable "cpu_credit_low_threshold" {
  type    = number
  default = 20
}
