output "repository_url" {
  description = "URL ECR-репозиторію"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN ECR-репозиторію"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Назва ECR-репозиторію"
  value       = aws_ecr_repository.main.name
}
