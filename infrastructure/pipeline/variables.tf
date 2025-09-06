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

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
  default     = "your-github-username/document-verifier"
}

variable "github_branch" {
  description = "GitHub branch to use for CodePipeline"
  type        = string
  default     = "main"
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

variable "s3_bucket_suffix_length" {
  description = "Length of random suffix for S3 bucket names"
  type        = number
  default     = 4
}