output "s3_bucket_name" {
  description = "Назва S3-бакета"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_url" {
  description = "URL S3-бакета"
  value       = "https://${aws_s3_bucket.terraform_state.bucket_regional_domain_name}"
}

output "s3_bucket_arn" {
  description = "ARN S3-бакета"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB-таблиці"
  value       = aws_dynamodb_table.terraform_locks.name
}
