# PayNest Take-Home Assignment (48 hours)

## Title
AWS App Runner Service Deployment with IaC

## Scenario
We’re launching a new microservice called **document-verifier**, which validates user documents uploaded from our frontend.  
This service should be built and deployed independently of our existing systems.

---

## Requirements
- Service must run on **AWS App Runner**, pulling its container image from **Amazon ECR**.  
- Deployment must be fully automated via **AWS CodePipeline**:
  - Source: GitHub  
  - Build: AWS CodeBuild  
  - Push image to ECR  
  - Deploy to App Runner  
- Store sensitive config values (e.g., verification API keys) in **AWS Secrets Manager** and load them at runtime.  
- Serve traffic through a **CloudFront distribution** in front of App Runner.  
- Add an **AWS WAF rule** to block requests from a known list of malicious IP addresses.  
- Log all requests to **CloudWatch Logs**.  
- Use **Route 53** to point `verify.paynest.com` to the CloudFront distribution.  
- Configure **App Runner’s auto-scaling** to handle increased request volume.  
- All infrastructure should be defined in **Terraform** or **AWS CloudFormation**.  

---

## Deliverables
- **Infrastructure as Code** for all required AWS resources.  
- **README file** including:  
  - Architecture diagram (can be hand-drawn or tool-generated).  
  - Explanation of security design decisions.  
  - Cost considerations and optimizations.  

---

## What We Are Evaluating
- Your ability to design AWS services from scratch using Infrastructure as Code.  
- Security best-practice awareness in a fintech context.  
- CI/CD automation skills.  
- Clarity and completeness of documentation.  
