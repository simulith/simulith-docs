# Service depth tiers — using all twenty-three matrix areas

Simulith ships **twenty-three** service areas on port **4566**. They do not all behave like AWS at the **same depth**. This page is the map for **“works like AWS”** without claiming hypervisor or global edge parity.

> **Operations detail:** [compatibility-matrix.md](compatibility-matrix.md) · **Percentages:** aws-parity-overview.md · **Day-to-day workflows:** [using-simulith.md](using-simulith.md) · **demoapp reference stack:** hybrid local stack (internal mirror path in monorepo).

---

## Three tiers (product bar)

| Tier | Meaning | “Like AWS” for… |
| --- | --- | --- |
| **1 — Runnable** | Requests change **real local state** your app can use (SQLite, subprocess Lambda, Docker sidecar, disk-backed S3, local crypto, SES outbox, …). | App code, workers, integration tests, most Console flows. |
| **2 — Contract / IaC** | API + persisted **metadata** so **Terraform / CLI / Serverless** apply and destroy without overlays; **no** matching data plane (no packets, no VM, no public DNS). | Unmodified modules, remote state, CI green paths — **demoapp Path C**. |
| **3 — Engine-faithful (target)** | Sidecar or host process where AWS would run compute, storage, or networking (Postgres today; optional EC2 SSH later — **FW-EC2-020**). | Bastion/EC2 apps, real block storage, resolver at edge — **only when a customer apply is blocked**. |

**North star** (`product-vision.md`): same CLI, SDK, and **unmodified IaC** locally and in AWS. Tier **2** is enough for most serverless + RDS stacks. Tier **3** is phased per service, not a big-bang clone of AWS.

```text
Customer goal                    Typical tier needed today
─────────────────────────────────────────────────────────
demoapp infra TF (Path C)      Tier 2 (+ RDS Tier 3 sidecar)
demoapp app + Serverless       Tier 1 app APIs + Tier 2 VPC metadata
EC2 bastion / SSH debugging        Tier 3 (not shipped — FW-EC2-020)
```

---

## Matrix — depth by service

| Service | Tier today | How to exercise it | Notes / backlog |
| --- | --- | --- | --- |
| **DynamoDB** | 1 | `simulith verify dynamodb` · Console **DynamoDB** · [dynamodb.md](dynamodb.md) | Full item/table lifecycle on SQLite. |
| **SQS** | 1 | `simulith verify sqs` · Console **SQS** | |
| **SSM** | 1 | `simulith verify ssm` · Console **SSM** | |
| **S3** | 1 | `simulith verify s3` · Console **S3** | Objects on local disk under runtime state. |
| **Lambda** | 1 | `simulith verify lambda` · Console invoke | Subprocess/runtime; **VpcConfig** reaches RDS Proxy when wired (). |
| **API Gateway** | 1 | `simulith verify apigateway` · Console | Includes authorizer subset (demoapp). |
| **Secrets Manager** | 1 | `simulith verify secretsmanager` | |
| **Cognito** | 1 (subset) | `simulith verify cognito` | No full hosted UI / some MFA paths — see [cognito.md](cognito.md). |
| **SES** | 1 | `simulith verify ses` · Console outbox | Local email capture, not SMTP to the internet. |
| **SNS** | 1 | `simulith verify sns` | |
| **EventBridge** | 1 | `simulith verify eventbridge` | Schedule + PutEvents. |
| **CloudWatch Logs** | 1 | `simulith verify cloudwatch` | |
| **CloudWatch Metrics** | 1 | `simulith verify cloudwatch` (metrics scenarios) | |
| **IAM** | 2 | `simulith verify iam` · Console **IAM** | Roles/policies for local evaluation; not full AWS account model. |
| **KMS** | 1 (local CMK) | `simulith verify kms` | Local encrypt/decrypt — [kms.md](kms.md). |
| **VPC** | 2 | `simulith verify vpc` · Console **VPC** | Subnets, SG, routes, endpoints — **metadata**; no packet NAT/PrivateLink — [vpc.md](vpc.md). |
| **RDS** | **3** (Postgres) | `simulith verify rds` · Console **RDS** | **Docker Postgres sidecar** + **Proxy TCP relay** — mount Docker socket — [rds.md](rds.md). |
| **Route 53** | 2 | `simulith verify route53` | Zones/records in SQLite; **no** public DNS resolution — [route53.md](route53.md). |
| **ACM** | 2 | `simulith verify acm` | DNS validation metadata — [acm.md](acm.md). |
| **CloudFront** | 2 | `simulith verify cloudfront` | Distribution/OAC metadata; local CDN patterns in green paths — [cloudfront.md](cloudfront.md). |
| **CloudFormation** | 1–2 (subset) | `simulith verify cloudformation` · Console | **Serverless v3 resource subset** — not full AWS CFN — [cloudformation.md](cloudformation.md). |
| **EC2 / EBS** | **3** (SSH) + 2 (EBS) | `simulith verify ec2` · Console **EC2** | **RunInstances** → Docker **SSH sidecar** on `127.0.0.1` (requires Docker) — [ebs.md](ebs.md#ec2-ssh-sidecar). EBS remains metadata-only. |
| **Cost Explorer** | 1 (local) | `simulith verify cost` · Console **Billing** | Local estimate only — [cost-explorer.md](cost-explorer.md). |

---

## demoapp — “all services we need”

The demoapp prod chain on Simulith is **documented and validated**. It uses **Tier 1** app services and **Tier 2** network/edge metadata plus **Tier 3 RDS**.

| Need | Simulith tier | Status |
| --- | --- | --- |
| App (DDB, Cognito, SES, EB, APIGW, Lambda, …) | 1 | ✅ Shipped B5–B6 |
| RDS + Proxy + Lambda → DB | 3 + 1 | ✅  (Docker socket) |
| VPC / VpcConfig | 2 + reachability | ✅  |
| IAM / KMS for secrets & proxy | 1–2 | ✅  |
| Route 53 / ACM / CloudFront | 2 | ✅  |
| **EC2** | — | **Not in demoapp prod chain** — metadata EC2 is enough for modules that only reference instances indirectly |

Full matrix: hybrid local stack — Service matrix.

---

## Checklist — use every shipped area locally

1. **Health** — [using-simulith.md — Verify](using-simulith.md#verify-simulith-is-running).
2. **Seed** — `simulith seed` or Console **Seed demo data** ([seed.md](seed.md)).
3. **Console tour** — one panel per matrix area ([console.md](console.md)).
4. **Verify all** — `simulith verify` (or per-service) from a host with **Docker** for RDS scenarios ([compatibility.md](compatibility.md)).
5. **Terraform** — green paths under [`runtime/examples/terraform/`](examples/terraform/).
6. **RDS / Lambda VPC** — `docker run` with `-v //var/run/docker.sock:/var/run/docker.sock` ([docker.md](docker.md)).

---

## Roadmap — depth → “more like AWS”

Prioritized when **customer apply** or **app runtime** blocks — not cosmetic parity.

| Priority | Item | Delivers |
| --- | --- | --- |
| P0 | Stay on **unmodified IaC** bar |  ✅ ·  |
| P1 | **Serverless / CFN** depth |  · `cloudformation/` |
| P1 | **EC2 SSH sidecar** (shipped runtime) | **FW-EC2-020** — Docker + `simulith verify ec2` **`instance-ssh-sidecar`** |
| P3 | VPC packet plane (NAT, NACL) | Out of scope unless blocked — [vpc.md](vpc.md) |

Study (internal): `simulith-data-plane-depth-roadmap`.

---

Last updated: 2026-11-24 (demoapp Path C + twenty-three matrix areas).
