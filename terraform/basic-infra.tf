locals {
  cluster_name            = "${var.entity_name}-cluster"
  alb_name                = "${var.entity_name}-alb"
  alb_tg_name             = "${var.entity_name}-tg"
  ecs_execution_role_name = "${var.entity_name}-ecs-exec-role"
  ecs_service_name        = "${var.entity_name}-service"
  ecr_repository_name     = "${var.entity_name}-repository"
}
data "aws_vpc" "ecs_vpc" {
  id = null
}
data "aws_subnet_ids" "ecs_subnet_ids" {
  vpc_id = data.aws_vpc.ecs_vpc.id
}
data "aws_subnet" "ecs_subnets" {
  for_each = data.aws_subnet_ids.ecs_subnet_ids.ids
  id       = each.value
}
resource "aws_lb" "ecs_alb" {
  name     = local.alb_name
  internal = false
  subnets  = [for subnet in data.aws_subnet.ecs_subnets : subnet.id]
}
resource "aws_lb_target_group" "ecs_alb_tg" {
  name        = local.alb_tg_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.ecs_vpc.id
  target_type = "ip"
}
resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
  }
}
resource "aws_iam_role" "ecs_execution_role" {
  name = local.ecs_execution_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}
resource "aws_ecs_cluster" "ecs_cluster" {
  name               = local.cluster_name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}
resource "aws_ecs_task_definition" "ecs_taskdef" {
  family                   = "webserver"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "nginx"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
}
resource "aws_ecs_service" "ecs_service" {
  name                 = local.ecs_service_name
  cluster              = aws_ecs_cluster.ecs_cluster.arn
  task_definition      = aws_ecs_task_definition.ecs_taskdef.arn
  desired_count        = 1
  force_new_deployment = true
  network_configuration {
    subnets          = [for subnet in data.aws_subnet.ecs_subnets : subnet.id]
    assign_public_ip = true ## false should also work
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 100
  }
}
resource "aws_ecr_repository" "ecs_ecr_repository" {
  name = local.ecr_repository_name
}