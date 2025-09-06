terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    bucket = "tf-state-file-bucket-025323792109"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random suffix for S3 bucket
resource "random_id" "bucket_suffix" {
  byte_length = var.s3_bucket_suffix_length
}

# Get ECR repository (created in Phase 1)
data "aws_ecr_repository" "document_verifier" {
  name = var.ecr_repository_name
}

# Secrets Manager for API Keys
resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${var.app_runner_service_name}/api-keys"
  description             = "API keys for document verification service"
  recovery_window_in_days = var.secrets_recovery_window_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "api_keys_version" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    verification_api_key = "your-verification-api-key-here"
    backup_api_key       = "your-backup-api-key-here"
  })
}

# App Runner IAM Roles
resource "aws_iam_role" "app_runner_instance_role" {
  name = "${var.app_runner_service_name}-app-runner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "app_runner_access_role" {
  name = "${var.app_runner_service_name}-app-runner-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_access" {
  role       = aws_iam_role.app_runner_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_policy" "app_runner_secrets_policy" {
  name        = "${var.app_runner_service_name}-secrets-policy"
  description = "Policy for App Runner to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.api_keys.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_secrets_attachment" {
  role       = aws_iam_role.app_runner_instance_role.name
  policy_arn = aws_iam_policy.app_runner_secrets_policy.arn
}

# Auto Scaling Configuration for App Runner
resource "aws_apprunner_auto_scaling_configuration_version" "document_verifier_scaling" {
  auto_scaling_configuration_name = "${var.app_runner_service_name}-scaling"

  min_size         = var.min_instances
  max_size         = var.max_instances
  max_concurrency  = var.max_concurrency

  tags = var.tags
}

# App Runner Service
resource "aws_apprunner_service" "document_verifier" {
  service_name = var.app_runner_service_name
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.document_verifier_scaling.arn

  source_configuration {
    auto_deployments_enabled = false

    image_repository {
      image_identifier      = "${data.aws_ecr_repository.document_verifier.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          NODE_ENV    = "production"
          AWS_REGION  = var.aws_region
          SECRET_NAME = aws_secretsmanager_secret.api_keys.name
        }
      }
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_access_role.arn
    }
  }

  instance_configuration {
    cpu               = var.app_runner_cpu
    memory            = var.app_runner_memory
    instance_role_arn = aws_iam_role.app_runner_instance_role.arn
  }

  health_check_configuration {
    healthy_threshold   = 2
    interval            = 10
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# WAF IP Set for blocking malicious IPs
resource "aws_wafv2_ip_set" "malicious_ips" {
  name  = "${var.app_runner_service_name}-malicious-ips"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = var.tags
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "document_verifier_waf" {
  name  = "${var.app_runner_service_name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockMaliciousIPs"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.malicious_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "BlockMaliciousIPsRule"
      sampled_requests_enabled    = true
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit          = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "DocumentVerifierWAF"
    sampled_requests_enabled    = true
  }

  tags = var.tags
}

# S3 Bucket for CloudFront Access Logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.app_runner_service_name}-cloudfront-logs-${random_id.bucket_suffix.hex}"

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_acl_ownership" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_pab" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "cloudfront_logs_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_logs_acl_ownership,
    aws_s3_bucket_public_access_block.cloudfront_logs_pab,
  ]

  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "cloudfront_logs_versioning" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_encryption" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for CloudFront
resource "aws_cloudwatch_log_group" "cloudfront_logs" {
  name              = "/aws/cloudfront/${var.app_runner_service_name}"
  retention_in_days = var.cloudwatch_retention_days

  tags = var.tags
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "document_verifier" {
  comment         = "CloudFront distribution for ${var.app_runner_service_name} service"
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = "PriceClass_All"

  origin {
    domain_name = replace(aws_apprunner_service.document_verifier.service_url, "https://", "")
    origin_id   = "AppRunnerOrigin"

    custom_origin_config {
      http_port              = 443
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "AppRunnerOrigin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  logging_config {
    include_cookies = false
    bucket         = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix         = "access-logs/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.document_verifier_waf.arn

  tags = var.tags
}