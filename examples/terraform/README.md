# Terraform examples — Simulith

Runnable root modules and stubs, organized **by AWS service**.

```text
runtime/examples/terraform/
├── README.md           ← this index
├── dynamodb/
│   ├── music/          ← minimal demo (apply OK)
│   └── user-table/     ← prod-derived subset (apply OK)
├── sqs/                              ← aws_sqs_queue apply + destroy (GetQueueAttributes, DeleteQueue tombstone)
└── ssm/
    ├── (root)            ← minimal /app/tf-demo/* demo
    └── parameters/     ← Loyaleasy-shaped paths; Simulith local uses `/SIMULITH/DEV/*`
```

Each subdirectory with `main.tf` is a **standalone** module: `cd` into it, then `terraform init && apply`.

**Endpoint:** Docker all-in-one (Console `:9080`) → `http://127.0.0.1:9080/runtime` in `terraform.tfvars.example` / `dev.tfvars.example`. Native / host `:4566` → `*.native.example`. **Real AWS** → workspace `aws` + `-var-file=terraform.aws-dev.tfvars` (DynamoDB, SQS) or `dev.aws.tfvars` (SSM parameters) — see [terraform-integration.md — Workspaces](../../docs/terraform-integration.md#workspaces-and--var-file-simulith-vs-real-aws).

## Green path status (apply → destroy)

Use **`terraform destroy`** for teardown in all modules below — Simulith implements **DeleteTable**, **DeleteQueue**, and **DeleteParameter**. Do **not** use `simulith reset` + `terraform state rm` unless you created resources outside Terraform state.

| Module | Apply | Destroy | Notes |
| --- | --- | --- | --- |
| [`dynamodb/music/`](dynamodb/music/) | Green | Green | Hash key demo |
| [`dynamodb/user-table/`](dynamodb/user-table/) | Green | Green | PK + 2 GSIs, tags, SSE, PITR metadata; `use_simulith_endpoint`; **`user.json` seed** — [README](dynamodb/user-table/README.md) |
| [`sqs/`](sqs/) | Green | Green | `app-queue-tf`; destroy ~60–90s on Simulith; [README](sqs/README.md) |
| [`ssm/`](ssm/) | Green | Green | Use `-parallelism=1` on apply and destroy; import documented |
| [`ssm/parameters/`](ssm/parameters/) | Green | Green | 27× `/SIMULITH/DEV/*` locally; `dev.tfvars` / `dev.aws.tfvars`; `-parallelism=1` — [README](ssm/parameters/README.md) |

Full walkthrough: [terraform-integration.md — Green path IaC](../../docs/terraform-integration.md#green-path-iac).

Guide: [terraform-integration.md](../../docs/terraform-integration.md) · Parity gaps: cursor/company/future-work/
