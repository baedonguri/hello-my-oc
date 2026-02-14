output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}

output "aws_region" {
  value = var.aws_region
}

output "project_name" {
  value = var.project_name
}

output "environment" {
  value = var.environment
}
