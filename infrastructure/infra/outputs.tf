output "app_runner_service_url" {
  description = "URL of the App Runner service"
  value       = "https://${aws_apprunner_service.document_verifier.service_url}"
}

output "app_runner_service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.document_verifier.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.document_verifier.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.document_verifier.domain_name
}

output "cloudfront_distribution_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.document_verifier.domain_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.document_verifier_waf.arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.api_keys.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudfront_logs.name
}

output "s3_logs_bucket_name" {
  description = "Name of the S3 bucket for CloudFront logs"
  value       = aws_s3_bucket.cloudfront_logs.bucket
}