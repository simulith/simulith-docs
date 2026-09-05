# Simulith Documentation

Public mirror of Simulith **user documentation** and **runnable examples**.

| Resource | Link |
| --- | --- |
| Product site | [simulith.dev](https://simulith.dev) |
| Docker Hub | [simulith/simulith](https://hub.docker.com/r/simulith/simulith) · [simulith/console](https://hub.docker.com/r/simulith/console) |
| This repo | `simulith/simulith-docs` — read-only mirror |

> **Source of truth:** the private `simulith/simulith` monorepo (`runtime/docs/`, `runtime/examples/`). This repository is a **read-only mirror** — do not edit here; changes are synced from release tags.

Generated from monorepo commit `10edb1e` on 2026-09-05.

## Start here

| Guide | Purpose |
| --- | --- |
| [Quickstart](quickstart.md) | Run Simulith in under 5 minutes |
| [Changelog](CHANGELOG.md) | Release notes by version |
| [Using Simulith (local vs AWS)](using-simulith.md) | After Docker is up — workflows and endpoints |
| [Docker](docker.md) | Images, volumes, health checks |
| [Console](console.md) | Web GUI at `:9080` |

## Tools & IaC

| Guide | Purpose |
| --- | --- |
| [AWS CLI examples](aws-cli-examples.md) | Copy-paste CLI cookbook |
| [SDK examples](sdk-examples.md) | Go, Node.js, Python (boto3) |
| [Terraform integration](terraform-integration.md) | Green-path apply/destroy |
| [Examples](examples/terraform/) | Runnable Terraform modules |

## Services

| Guide | Purpose |
| --- | --- |
| [DynamoDB](dynamodb.md) | Tables and items |
| [SQS](sqs.md) | Queues and messages |
| [SSM](ssm.md) | Parameter Store |
| [S3](s3.md) | Buckets and objects |
| [Lambda](lambda.md) | Functions, invoke, SQS ESM; seeded demo-fn |
| [API Gateway](apigateway.md) | REST API CRUD (management API) |
| [Secrets Manager](secretsmanager.md) | Secret CRUD |
| [EventBridge](eventbridge.md) | Schedule rules → Lambda; seeded demo-rule |
| [Cognito](cognito.md) | User Pool + Admin* + JWKS; seeded demo-pool |
| [SES](ses.md) | Identity, templates, Send* (local outbox); seeded demo-template |
| [VPC](vpc.md) | VPC, subnets, security groups |
| [RDS](rds.md) | PostgreSQL + RDS Proxy (Docker sidecar) |
| [IAM](iam.md) | Roles and policies (RDS Proxy) |
| [KMS](kms.md) | Customer master keys + encrypt/decrypt |
| [Route 53](route53.md) | Hosted zones + DNS records |
| [ACM](acm.md) | DNS-validated certificates |
| [CloudFront](cloudfront.md) | OAC + distributions (local CDN metadata) |
| [CloudFormation](cloudformation.md) | Stack control plane subset (Serverless path) |

## Compatibility

| Guide | Purpose |
| --- | --- |
| [Compatibility matrix](compatibility-matrix.md) | Operation × verify coverage — **start here** for limits |
| [AWS parity overview](aws-parity-overview.md) | Deeper API summary by service (evaluators) |
| [Compatibility / verify](compatibility.md) | `simulith verify` and reports |
| [Trust bundle](trust-bundle.md) | Enterprise evaluation package |

## Platform

| Guide | Purpose |
| --- | --- |
| [Admin API](admin-api.md) | `/_simulith/v1/*` routes |
| [Persistence](persistence.md) | SQLite state |
| [Seed](seed.md) | Demo fixtures |
| [Snapshot](snapshot.md) | Save/restore state |
