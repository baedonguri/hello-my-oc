output "project" {
  value = {
    name        = var.project_name
    environment = var.environment
    region      = var.aws_region
  }
}
