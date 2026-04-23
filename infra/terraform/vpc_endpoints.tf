# ═══════════════════════════════════════════════════════════════════
# vpc_endpoints.tf – Required for ECS private subnet + SSM access
# Fixes ECS "unable to retrieve secrets from SSM" error
# ═══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# Security Group for VPC Endpoints
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.app_name}-${var.environment}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from ECS tasks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # you can restrict later to VPC CIDR
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
# SSM Parameter Store Endpoint
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ssm-endpoint"
  })
}

# ─────────────────────────────────────────────────────────────
# SSM Messages Endpoint (required for ECS exec + secrets)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ssmmessages-endpoint"
  })
}

# ─────────────────────────────────────────────────────────────
# EC2 Messages Endpoint (required for SSM agent communication)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ec2messages-endpoint"
  })
}

# ─────────────────────────────────────────────────────────────
# ECR API Endpoint (needed for pulling images)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ecr-api-endpoint"
  })
}

# ─────────────────────────────────────────────────────────────
# ECR Docker Endpoint (image pulls)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-ecr-dkr-endpoint"
  })
}

# ─────────────────────────────────────────────────────────────
# CloudWatch Logs Endpoint (for ECS logging)
# ─────────────────────────────────────────────────────────────
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.environment}-logs-endpoint"
  })
}