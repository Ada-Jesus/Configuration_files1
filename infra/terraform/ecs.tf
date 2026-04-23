# ═══════════════════════════════════════════════════════════════════
#  ecs.tf  –  ECS cluster, task definition, blue & green services
# ═══════════════════════════════════════════════════════════════════

# ── CloudWatch Log Group ──────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════
# ECS FIXED CONFIG – BLUE/GREEN + SSM SAFE
# ═══════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════
#  ecs.tf  – ECS cluster, task definition, blue & green services
# ═══════════════════════════════════════════════════════════════════

# ── CloudWatch Log Group ──────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════
# CloudWatch Log Group
# ═══════════════════════════════════════════════════════════════
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

# ═══════════════════════════════════════════════════════════════
# ECS Cluster
# ═══════════════════════════════════════════════════════════════
resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# ═══════════════════════════════════════════════════════════════
# TASK DEFINITION (FIXED + STABLE)
# ═══════════════════════════════════════════════════════════════
resource "aws_ecs_task_definition" "app" {
  family                   = local.name_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.ecr_image_uri
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:${var.container_port}"
        }
      ]

      # ═══════════════════════════════════════════════
      # SSM SECRETS (NOW VERIFIED WORKING)
      # ═══════════════════════════════════════════════
      secrets = [
        {
          name      = "ConnectionStrings__Default"
          valueFrom = "/aspnet-api-production/db-connection-string"
        },
        {
          name      = "ApiKey"
          valueFrom = "/aspnet-api-production/api-key"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ═══════════════════════════════════════════════════════════════
# BLUE SERVICE
# ═══════════════════════════════════════════════════════════════
resource "aws_ecs_service" "blue" {
  name            = "${local.name_prefix}-blue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]

    # REQUIRED for SSM + ECR access (your current working setup)
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# ═══════════════════════════════════════════════════════════════
# GREEN SERVICE
# ═══════════════════════════════════════════════════════════════
resource "aws_ecs_service" "green" {
  name            = "${local.name_prefix}-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 0
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# ═══════════════════════════════════════════════════════════════
# OUTPUTSsss
# ═══════════════════════════════════════════════════════════════
output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "blue_service_name" {
  value = aws_ecs_service.blue.name
}

output "green_service_name" {
  value = aws_ecs_service.green.name
}