# ═════════════════════════════════════════════════════
# ECS CLUSTER
# ═════════════════════════════════════════════════════
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}"
}

# ═════════════════════════════════════════════════════
# CLOUDWATCH LOG GROUP (MISSING IN YOUR FILE)
# ═════════════════════════════════════════════════════
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7
}

# ═════════════════════════════════════════════════════
# IAM ROLE (EXECUTION ROLE FIXED)
# ═════════════════════════════════════════════════════
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ═════════════════════════════════════════════════════
# TASK DEFINITION (HARDENED)
# ═════════════════════════════════════════════════════
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "aspnet-api"

      # 🔥 FIX: prevent empty image issues
      image = var.image_uri != "" ? var.image_uri : "public.ecr.aws/nginx/nginx:latest"

      essential = true

      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }]

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "production"
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:8080"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ═════════════════════════════════════════════════════
# SECURITY GROUP
# ═════════════════════════════════════════════════════
resource "aws_security_group" "ecs_tasks" {
  name   = "${local.name_prefix}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ═════════════════════════════════════════════════════
# BLUE SERVICE
# ═════════════════════════════════════════════════════
resource "aws_ecs_service" "blue" {
  name            = "${local.name_prefix}-blue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "aspnet-api"
    container_port   = 8080
  }
}

# ═════════════════════════════════════════════════════
# GREEN SERVICE
# ═════════════════════════════════════════════════════
resource "aws_ecs_service" "green" {
  name            = "${local.name_prefix}-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "aspnet-api"
    container_port   = 8080
  }
}