variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "document-verifier"
}

variable "app_runner_service_name" {
  description = "Name of the App Runner service"
  type        = string
  default     = "document-verifier"
}

variable "app_runner_cpu" {
  description = "CPU configuration for App Runner"
  type        = string
  default     = "1024"
}

variable "app_runner_memory" {
  description = "Memory configuration for App Runner"
  type        = string
  default     = "2048"
}

variable "min_instances" {
  description = "Minimum number of App Runner instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of App Runner instances"
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum concurrency per instance"
  type        = number
  default     = 100
}

variable "domain_name" {
  description = "Custom domain name (e.g., verify.paynest.com)"
  type        = string
  default     = ""
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses to block via WAF"
  type        = list(string)
  default = [
    "192.0.2.0/24",
    "198.51.100.0/24",
    "203.0.113.0/24"
  ]
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "PayNest"
    Service     = "document-verifier"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "tf-state-file-bucket-025323792109"
}

variable "secrets_recovery_window_days" {
  description = "Recovery window for Secrets Manager secret deletion"
  type        = number
  default     = 7
}

variable "s3_bucket_suffix_length" {
  description = "Length of random suffix for S3 bucket names"
  type        = number
  default     = 4
}