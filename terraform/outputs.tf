output "ecr_url" {
  value       = aws_ecr_repository.ecs_ecr_repository.repository_url
  description = "AWS ECR repository url"
}
output "ecr_repository_name" {
  value       = aws_ecr_repository.ecs_ecr_repository.name
  description = "AWS ECR repository name"
}
output "ecs_service" {
  value       = aws_ecs_service.ecs_service.name
  description = "The ECS service name"
}
output "ecs_cluster" {
  value       = aws_ecs_cluster.ecs_cluster.name
  description = "The ECS cluster name"
}