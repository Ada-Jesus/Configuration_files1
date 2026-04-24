# ═══════════════════════════════════════════════════════════════════
# vpc_endpoints.tf – Required for ECS private subnet + SSM access
# Fixes ECS "unable to retrieve secrets from SSM" error
# ═══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.app_name}-${var.environment}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from ECS tasks only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    security_groups = [
      aws_security_group.ecs_tasks.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-vpce-sg"
  })
}

# ─────────────────────────────────────────────────────────────
# ECR API (metadata)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ecr-api"
  })
}

# ─────────────────────────────────────────────────────────────
# ECR DKR (image pull)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ecr-dkr"
  })
}

# ─────────────────────────────────────────────────────────────
# SSM (parameters / secrets)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ssm"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ssm-messages"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ec2-messages"
  })
}

# ─────────────────────────────────────────────────────────────
# CLOUDWATCH LOGS
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-logs"
  })
}