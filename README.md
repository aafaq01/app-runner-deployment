# PayNest Document Verifier - AWS App Runner Deployment

A secure, scalable document verification microservice deployed on AWS App Runner with complete Infrastructure as Code automation using Terraform.

## 🏗️ Architecture Overview

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌───────────────┐
│   GitHub    │───▶│ CodePipeline │───▶│ CodeBuild   │───▶│     ECR       │
│ Repository  │    │              │    │             │    │  Repository   │
└─────────────┘    └──────────────┘    └─────────────┘    └───────────────┘
                                                                   │
                   ┌──────────────┐    ┌─────────────┐    ┌───────▼───────┐
                   │ CloudFront   │───▶│    WAF      │───▶│  App Runner   │
                   │ Distribution │    │             │    │   Service     │
                   │              │    │             │    │               │
                   └──────────────┘    └─────────────┘    └───────────────┘
                                                                   │
                   ┌──────────────┐    ┌─────────────┐    ┌───────▼───────┐
                   │ CloudWatch   │    │   Secrets   │    │  Application  │
                   │    Logs      │    │  Manager    │    │   Container   │
                   └──────────────┘    └─────────────┘    └───────────────┘
```

## 🚀 Key Features

- **Two-Phase Deployment**: Separate CI/CD pipeline and runtime infrastructure
- **Auto-Scaling**: App Runner with configurable scaling parameters
- **Security**: WAF protection, IP blocking, rate limiting, secrets management
- **Monitoring**: CloudWatch logs, S3 access logs, health checks
- **Cost-Optimized**: Right-sized resources with lifecycle policies

## 📁 Project Structure

```
├── infrastructure/
│   ├── pipeline/              # Phase 1: CI/CD Pipeline
│   │   ├── main.tf           # ECR + CodePipeline + GitHub
│   │   ├── variables.tf      # Pipeline variables
│   │   ├── outputs.tf        # Pipeline outputs
│   │   └── terraform.tfvars  # Pipeline configuration
│   └── infra/                # Phase 2: Runtime Infrastructure
│       ├── main.tf           # App Runner + CloudFront + WAF
│       ├── variables.tf      # Infrastructure variables
│       ├── outputs.tf        # Infrastructure outputs
│       └── terraform.tfvars  # Infrastructure configuration
├── application/              # Application code
│   ├── src/server.js        # Express.js REST API
│   ├── package.json         # Node.js dependencies
│   ├── Dockerfile           # Container configuration
│   └── tests/               # Test files
├── buildspec.yml            # CodeBuild configuration
└── REQUIREMENTS.md          # Project requirements
```

## 🚀 Deployment Guide

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- GitHub repository set up
- S3 bucket for Terraform state: `tf-state-file-bucket-025323792109`

### Phase 1: Deploy CI/CD Pipeline

1. **Configure Pipeline Variables**
   ```bash
   cd infrastructure/pipeline
   # Edit terraform.tfvars with your values:
   # - github_repository = "your-username/your-repo"
   # - github_branch = "master"
   ```

2. **Deploy Pipeline Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Activate GitHub Connection**
   ```bash
   # After deployment, manually activate the CodeStar connection in AWS Console
   # Go to Developer Tools > Settings > Connections
   # Complete the GitHub authorization
   ```

4. **Trigger Initial Build**
   ```bash
   git push origin master  # This will trigger the pipeline
   ```

### Phase 2: Deploy Runtime Infrastructure

1. **Wait for Initial Image**
   Ensure Phase 1 pipeline has successfully built and pushed at least one Docker image to ECR.

2. **Configure Infrastructure Variables**
   ```bash
   cd infrastructure/infra
   # terraform.tfvars is already configured with sensible defaults
   # Customize as needed (scaling, WAF settings, etc.)
   ```

3. **Deploy Runtime Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Testing the Deployment

```bash
# Get URLs from Terraform outputs
terraform output

# Test health endpoint (App Runner direct)
curl https://[app-runner-url]/health

# Test health endpoint (CloudFront CDN)
curl https://[cloudfront-url]/health

# Test document verification
curl -X POST https://[cloudfront-url]/verify \
  -H "Content-Type: application/json" \
  -d '{"document":"test.pdf"}'
```

## 🔧 Configuration

### Key Variables (Phase 1 - Pipeline)

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS deployment region |
| `ecr_repository_name` | `document-verifier` | ECR repository name |
| `github_repository` | `your-username/repo` | GitHub repo (owner/name) |
| `github_branch` | `main` | Git branch for CI/CD |

### Key Variables (Phase 2 - Infrastructure)

| Variable | Default | Description |
|----------|---------|-------------|
| `min_instances` | `1` | Minimum App Runner instances |
| `max_instances` | `5` | Maximum App Runner instances |
| `max_concurrency` | `100` | Max concurrent requests per instance |
| `app_runner_cpu` | `1024` | CPU units (1 vCPU) |
| `app_runner_memory` | `2048` | Memory in MB (2 GB) |
| `waf_rate_limit` | `2000` | WAF rate limit (requests/5min) |
| `blocked_ip_addresses` | `[]` | List of IPs to block |

## 🔒 Security Features

### Network Security
- **WAF Protection**: IP blocking and rate limiting at CloudFront edge
- **HTTPS Enforcing**: All traffic redirected to HTTPS
- **Origin Protection**: App Runner only accessible via CloudFront

### Application Security
- **Secrets Management**: API keys stored in AWS Secrets Manager
- **Container Security**: Non-root user, minimal Alpine base image
- **Image Scanning**: ECR vulnerability scanning enabled

### Access Control
- **IAM Roles**: Least privilege access for all services
- **Service Isolation**: Separate roles for App Runner, CodeBuild, Pipeline
- **Network Isolation**: Private service communication

## 💰 Cost Optimization

### Current Configuration
- **App Runner**: ~$20-50/month (1 vCPU, 2GB RAM, auto-scaling)
- **CloudFront**: ~$5-15/month (depends on traffic)
- **ECR**: ~$2-5/month (image storage)
- **Other Services**: ~$5-10/month (WAF, Secrets, S3, CloudWatch)

### Cost Controls
- Lifecycle policies for ECR images (keep last 30)
- CloudWatch log retention (30 days)
- Auto-scaling with minimum instances
- S3 bucket versioning and cleanup

## 📊 Monitoring

### Available Metrics
- **App Runner**: Service URL, status, scaling metrics
- **CloudFront**: Distribution URL, cache performance
- **Pipeline**: Build status, deployment history
- **Security**: WAF blocks, rate limit triggers

### Log Locations
- **Application Logs**: CloudWatch `/aws/apprunner/[service-name]`
- **Build Logs**: CloudWatch `/aws/codebuild/[project-name]`
- **CloudFront Logs**: S3 bucket with access patterns
- **WAF Logs**: CloudWatch WAF log group

## 🔧 Management Commands

### Update Application
```bash
# Make code changes and push to trigger automatic deployment
git add .
git commit -m "Update application"
git push origin master
```

### Scale App Runner Service
```bash
# Update terraform.tfvars in infrastructure/infra/
min_instances = 2
max_instances = 10

# Apply changes
terraform apply
```

### Update WAF Rules
```bash
# Add IPs to block in terraform.tfvars
blocked_ip_addresses = [
  "192.0.2.0/24",
  "203.0.113.0/24"
]

# Apply changes
terraform apply
```

## 🐛 Troubleshooting

### Common Issues

1. **Pipeline Build Failure**
   - Check CodeBuild logs in CloudWatch
   - Verify Docker build process
   - Ensure all dependencies are in package.json

2. **App Runner Service Failed**
   - Verify Docker image exists in ECR
   - Check health endpoint implementation
   - Review IAM permissions for service role

3. **CloudFront 502 Errors**
   - Ensure App Runner service is running
   - Check origin health in CloudFront console
   - Verify security group and network access

## 🧹 Cleanup

To destroy all resources:

```bash
# Destroy Phase 2 first (has dependencies on Phase 1)
cd infrastructure/infra
terraform destroy

# Then destroy Phase 1
cd ../pipeline
terraform destroy
```

**Note**: ECR images and S3 buckets with content may need manual deletion.

## 📝 Architecture Decisions

### Two-Phase Approach
- **Phase 1** creates the CI/CD pipeline and ECR repository
- **Phase 2** deploys runtime infrastructure that depends on built images
- This avoids chicken-and-egg problems with App Runner requiring existing images

### Technology Choices
- **App Runner**: Serverless container service, no cluster management
- **CloudFront**: Global CDN with WAF integration
- **GitHub Actions Alternative**: CodePipeline for AWS-native CI/CD
- **Terraform**: Infrastructure as Code with remote state management

This deployment provides a production-ready, secure, and scalable foundation for document verification services in the PayNest fintech ecosystem.