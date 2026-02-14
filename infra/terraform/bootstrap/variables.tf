variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type = string
}

variable "project_name" {
  type    = string
  default = "hello-my-oc"
}

variable "environment" {
  type    = string
  default = "production"
}
