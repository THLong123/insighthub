# Day 3 AI Prompt Log

```text
Prompt 1:
Create a Terraform module in infra/ for InsightHub on AWS.
Constraints: use an existing EKS cluster and VPC, create only the application
namespace and managed services. RDS PostgreSQL 16 must be private, encrypted,
and suitable for pgvector. ElastiCache Redis must be private, encrypted, and
used for the async ingestion queue. Use Multi-AZ defaults unless a human accepts
the lab cost tradeoff. Use IRSA for pod AWS access. Store generated credentials
in AWS Secrets Manager. Do not hardcode any secret.

Prompt 2:
Review the Terraform as a security gate. Make sure RDS is not public, Redis is
not public, encryption is enabled, provider versions are pinned, IAM avoids
wildcards, and all secrets are generated or read from secret managers.

Prompt 3:
Create a GitHub Actions workflow for InsightHub with build matrix for web, api,
and ingestion-worker. Add test, scan with Trivy and Checkov, Terraform fmt/lint/
validate/plan, and deploy to EKS only from main. Use GitHub Secrets and OIDC.

Prompt 4:
Find any hardcoded credentials in Kubernetes manifests and replace them with
Kubernetes Secret references so the Day 3 pipeline can inject runtime secrets.
```
