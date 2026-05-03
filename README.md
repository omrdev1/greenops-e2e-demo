# GreenOps E2E Demo

A demo Terraform repository for testing [GreenOps CLI](https://github.com/omrdev1/greenops-cli) end-to-end.

## What this repo does

Open a PR → GreenOps Action runs → carbon + cost analysis posted as a PR comment → data appears in [GreenOps Dashboard](https://greenops-dashboard.vercel.app).

## Infrastructure

Intentionally uses high-carbon instance types in `us-east-1` so GreenOps has meaningful recommendations to show:

| Resource | Type | Region | GreenOps recommendation |
|---|---|---|---|
| `aws_instance.web` | m5.xlarge | us-east-1 | UPGRADE → m6g.xlarge or shift to eu-north-1 |
| `aws_instance.api` | m5.large | us-east-1 | UPGRADE → m6g.large or shift to eu-north-1 |
| `aws_db_instance.main` | db.m5.large | us-east-1 | UPGRADE → db.m6g.large or shift to eu-north-1 |

## Setup

1. Add `GREENOPS_API_KEY` to repo secrets — get your key from [greenops-dashboard.vercel.app](https://greenops-dashboard.vercel.app)
2. Open a PR that modifies any `.tf` file
3. GreenOps runs automatically — no AWS account needed

## Note

Uses mock AWS credentials. Terraform runs in plan-only mode (`-backend=false`). Nothing is provisioned.
