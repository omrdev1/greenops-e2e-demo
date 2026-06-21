# GreenOps E2E Demo

A demo Terraform repository for testing [GreenOps CLI](https://github.com/omrdev1/greenops-cli) end to end, against a real `terraform plan`, not a synthetic fixture.

## What this repo does

Open a PR. GreenOps Action runs a real `terraform init` / `terraform plan` / `terraform show -json`, then carbon and cost analysis is posted as a PR comment, and the run appears in [GreenOps Dashboard](https://greenops-dashboard.vercel.app).

## Infrastructure

Intentionally uses high-carbon instance types in `us-east-1` so GreenOps has meaningful recommendations to show:

| Resource | Type | Region | GreenOps recommendation |
|---|---|---|---|
| `aws_instance.web` | m5.xlarge | us-east-1 | UPGRADE to m6g.xlarge or shift to eu-north-1 |
| `aws_instance.api` | m5.xlarge | us-east-1 | UPGRADE to m6g.xlarge or shift to eu-north-1 |
| `aws_db_instance.main` | db.m5.large | us-east-1 | UPGRADE to db.m6g.large or shift to eu-north-1 |
| `aws_eks_node_group.workers` | m5.large x2 (autoscaling minimum, desired is 3) | us-east-1 | UPGRADE to m6g.large or shift to eu-north-1, applied across the whole node group |

## Setup

1. Add `GREENOPS_API_KEY` to repo secrets. Get your key from [greenops-dashboard.vercel.app](https://greenops-dashboard.vercel.app)
2. Open a PR that modifies any `.tf` file
3. GreenOps runs automatically, no AWS account needed

## Note

Uses mock AWS credentials (`access_key`/`secret_key` set to placeholder values, `skip_credentials_validation` and related flags enabled in the provider block). `terraform plan` succeeds against these without ever calling AWS. Nothing is provisioned, no real account is touched, and no cost is incurred.
