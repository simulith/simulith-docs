# Terraform examples — Simulith

Runnable root modules and stubs, organized **by AWS service**.

```text
runtime/examples/terraform/
├── README.md           ← this index
├── dynamodb/
│   ├── music/          ← minimal demo (apply OK)
│   └── user-table/     ← prod-derived subset (apply OK)
├── sqs/                ← aws_sqs_queue apply + destroy (GetQueueAttributes, DeleteQueue tombstone)
├── ssm/
│   ├── (root)          ← minimal /app/tf-demo/* demo
│   └── parameters/     ← platform parameter paths; Simulith local uses `/SIMULITH/DEV/*`
├── s3/                 ← aws_s3_bucket + aws_s3_object apply + destroy (s3_use_path_style)
├── lambda/             ← aws_lambda_function + aws_sqs_queue + event source mapping
├── apigateway/         ← RestApi + Lambda AWS_PROXY + stage + permission
├── secretsmanager/     ← aws_secretsmanager_secret + secret_version
├── cognito/            ← aws_cognito_user_pool + client + group
├── ses/                ← aws_ses_email_identity + template
├── eventbridge/        ← rate rule → Lambda target
├── vpc/                ← aws_vpc + subnet + SG (network-min)
├── rds/                ← postgres-min + proxy-min (Docker sidecar)
├── iam/                ← proxy-roles-min (RDS Proxy role wiring)
├── kms/                ← cmk-min (CMK + alias)
├── lambda-vpc-rds/     ← full-stack-min (Lambda VpcConfig → RDS proxy)
└── secretsmanager-lambda/  ← secret data source → Lambda environment
└── dynamodb-sqs/           ← table + queue fan-out
└── s3-lambda/              ← bucket notification → Lambda
```

**Honest integration examples:** [`../aws-cli/lambda/`](../aws-cli/lambda/) · [`../aws-cli/secretsmanager/`](../aws-cli/secretsmanager/) · [`../aws-cli/dynamodb-sqs/`](../aws-cli/dynamodb-sqs/) · [`../aws-cli/s3/`](../aws-cli/s3/) · [`../aws-cli/s3-lambda/`](../aws-cli/s3-lambda/) · [`../aws-cli/ssm/`](../aws-cli/ssm/) · Lambda env in [`lambda/README`](lambda/README.md) · secret → env in [`secretsmanager-lambda/README`](secretsmanager-lambda/README.md) · fan-out in [`dynamodb-sqs/README`](dynamodb-sqs/README.md) · S3 lifecycle in [`../aws-cli/s3/`](../aws-cli/s3/) · S3→Lambda in [`s3-lambda/README`](s3-lambda/README.md) · SSM path in [`ssm/parameters/README`](ssm/parameters/README.md)

Each subdirectory with `main.tf` is a **standalone** module: `cd` into it, then `terraform init && apply`.

**Endpoint:** Docker all-in-one (Console `:9080`) → `http://127.0.0.1:9080/runtime` in `terraform.tfvars.example` / `dev.tfvars.example`. Native / host `:4566` → `*.native.example`. **Real AWS** → workspace `aws` + `-var-file=terraform.aws-dev.tfvars` (DynamoDB, SQS) or `dev.aws.tfvars` (SSM parameters) — see [terraform-integration.md — Workspaces](../../terraform-integration.md#workspaces-and--var-file-simulith-vs-real-aws).

## Green path status (apply → destroy)

Use **`terraform destroy`** for teardown in all modules below — Simulith implements **DeleteTable**, **DeleteQueue**, and **DeleteParameter**. Do **not** use `simulith reset` + `terraform state rm` unless you created resources outside Terraform state.

| Module | Apply | Destroy | Notes |
| --- | --- | --- | --- |
| [`dynamodb/music/`](dynamodb/music/) | Green | Green | Hash key demo |
| [`dynamodb/user-table/`](dynamodb/user-table/) | Green | Green | PK + 2 GSIs, tags, SSE, PITR metadata; `use_simulith_endpoint`; **`user.json` seed** — [README](dynamodb/user-table/README.md) |
| [`sqs/`](sqs/) | Green | Green | `app-queue-tf`; destroy ~60–90s on Simulith; [README](sqs/README.md) |
| [`ssm/`](ssm/) | Green | Green | Use `-parallelism=1` on apply and destroy; import documented |
| [`ssm/parameters/`](ssm/parameters/) | Green | Green | 27× `/SIMULITH/DEV/*` locally; `dev.tfvars` / `dev.aws.tfvars`; `-parallelism=1` — [README](ssm/parameters/README.md) |
| [`s3/`](s3/) | Green | Green | 1 bucket + 2 objects; `s3_use_path_style = true`; [README](s3/README.md) |
| [`lambda/`](lambda/) | Green | Green | 1 function + 1 queue + 1 ESM; **env vars** + in-place config update on re-apply |
| [`apigateway/`](apigateway/) | Green | Green | 8 resources; `endpoints { apigateway, lambda }`; `-parallelism=1`; [README](apigateway/README.md) |
| [`secretsmanager/`](secretsmanager/) | Green | Green | 2 resources; `endpoints { secretsmanager }`; `-parallelism=1`; [README](secretsmanager/README.md) |
| [`secretsmanager-lambda/`](secretsmanager-lambda/) | Green | Green | 3 resources + data source; `endpoints { secretsmanager, lambda }`; `-parallelism=1`; [README](secretsmanager-lambda/README.md) |
| [`dynamodb-sqs/`](dynamodb-sqs/) | Green | Green | 1 table + 1 queue; `endpoints { dynamodb, sqs }`; destroy ~60–90s; [README](dynamodb-sqs/README.md) |
| [`s3-lambda/`](s3-lambda/) | Green | Green | 1 bucket + 1 Lambda + notification; `endpoints { s3, lambda }`; `-parallelism=1`; [README](s3-lambda/README.md) |
| [`vpc/network-min/`](vpc/network-min/) | Green | Green | VPC + subnet + SG + gateway endpoints; `-parallelism=1`; [README](vpc/network-min/README.md) |

### B7+ examples (apply local — formal green path pending FW-*-003)

Runnable modules with documented limits. **`terraform destroy`** coverage is tracked per ****, ****, **** — use module READMEs until those stories close.

| Module | Apply | Destroy | Notes |
| --- | --- | --- | --- |
| [`rds/postgres-min/`](rds/postgres-min/) | Local | TBD | Postgres sidecar — **Docker required**; [README](rds/postgres-min/README.md) |
| [`rds/proxy-min/`](rds/proxy-min/) | Local | TBD | RDS Proxy + sidecar; Docker required |
| [`iam/proxy-roles-min/`](iam/proxy-roles-min/) | Local | TBD | IAM role/policy for RDS Proxy |
| [`kms/cmk-min/`](kms/cmk-min/) | Local | TBD | CMK + alias |
| [`lambda-vpc-rds/full-stack-min/`](lambda-vpc-rds/full-stack-min/) | Local | TBD | Lambda VpcConfig → RDS proxy; Docker required |

Full walkthrough: [terraform-integration.md — Green path IaC](../../terraform-integration.md#green-path-iac).

Guide: [terraform-integration.md](../../terraform-integration.md) · Parity gaps: [aws-parity-overview.md](../../aws-parity-overview.md)
