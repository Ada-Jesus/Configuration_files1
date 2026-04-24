# ═══════════════════════════════════════════════════════════════════
# security_groups.tf – ALB and ECS task security groups
# ═══════════════════════════════════════════════════════════════════

# ── ALB Security Group ────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ⚠️ Test listener - consider restricting to CI/CD IPs if possible
  ingress {
    description = "Test listener (CI/CD only recommended)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"

    # safer default: still open, but marked clearly
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ── ECS Task Security Group ───────────────────────────────────────
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS tasks security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "ALB traffic only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound (ECR, SSM, CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}