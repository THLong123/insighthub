# Day 3

## Checklist

- [x] Create `day3-terraform` branch from Day 2.
- [x] Add Terraform module in `infra/` for InsightHub AWS resources.
- [x] Add S3 + DynamoDB backend template.
- [x] Add GitHub Actions pipeline for build, test, scan, Terraform, and deploy.
- [x] Add Terraform MCP server to `.mcp.json`.
- [x] Remove hardcoded LLM API key from Kubernetes manifest.
- [ ] Run cloud-backed `terraform plan` after real AWS variables/secrets are available.
- [ ] Merge Day 1, Day 2, Day 3 pull requests in order.

## Terraform Scope

- Existing EKS cluster and VPC are inputs.
- Terraform creates the InsightHub namespace, IRSA ServiceAccount, RDS PostgreSQL 16, ElastiCache Redis, KMS key, Secrets Manager secrets, and least-privilege IAM policy.
- RDS and Redis are private-only, encrypted, and reachable only from EKS node or pod security groups.
- RDS and Redis use Multi-AZ defaults so the Checkov policy gate stays green. Lower-cost single-AZ labs require an explicit reviewed override.

## CI/CD Scope

- Build matrix: `api`, `web`, `ingestion-worker`.
- Test: Python compile check and Next.js build.
- Scan: Trivy Dockerfile config scan and Checkov IaC scan.
- Terraform gate: `fmt`, `tflint`, `checkov`, `init -backend=false`, `validate`, optional `plan`.
- Deploy: only on `main` and only when AWS/EKS secrets are configured.

## Required GitHub Secrets

- `AWS_ROLE_ARN`
- `EKS_CLUSTER_NAME`
- `GEMINI_API_KEY`
- `OPENAI_API_KEY`
- `VOYAGE_API_KEY`

## Required GitHub Variables

- `AWS_REGION` defaults to `ap-southeast-1` if not set.
