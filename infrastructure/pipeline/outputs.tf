output "ecr_repository_uri" {
  description = "URI of the ECR repository"
  value       = aws_ecr_repository.document_verifier.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.document_verifier.name
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  value       = aws_codestarconnections_connection.github.arn
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.document_verifier.name
}

output "codepipeline_artifacts_bucket" {
  description = "Name of the CodePipeline artifacts S3 bucket"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}