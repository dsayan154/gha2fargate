output "ecr_url" {
  value       = aws_ecr_repository.ecs_ecr_repository.repository_url
  description = "AWS ECR repository url"
}