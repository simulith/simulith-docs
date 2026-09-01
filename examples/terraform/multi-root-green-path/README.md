# Production multi-root green path — vpc → subnets → secrets → postgresdb → proxydb → ses → cognito → parameters → dynamodb → web (Simulith)

Generic **eleven-step** graph matching production apply order with S3 remote state between roots. Names are `demoapp` / `demo-terraform-state`.

```text
terraform-state-min/           local state → versioned bucket + lock table
multi-root-green-path/
  01-vpc/                      backend "s3" → production vpc/ shape (7 resources)
  02-subnets/                  backend "s3" + terraform_remote_state → subnets/ shape (12 resources)
  03-secrets/                  backend "s3" + terraform_remote_state → secrets/ shape (6 resources)
  04-postgresdb/               backend "s3" + terraform_remote_state → postgresdb/ shape (4 resources)
  05-proxydb/                  backend "s3" + terraform_remote_state → proxydb/ shape (7 resources)
  06-ses/                      backend "s3" → production ses/ shape (2 resources)
  07-cognito/                  backend "s3" → production cognito/ shape (12 resources)
  08-parameters/               backend "s3" + terraform_remote_state → parameters/ shape (26 resources)
  09-dynamodb/                 backend "s3" → production dynamodb/ shape (1 resource — user table)
  10-web/                      backend "s3" → production web/ shape (Route53 + ACM + S3 + CloudFront)
```

Single-root twins: [`../vpc-root/`](../vpc-root/) · [`../subnets/`](../subnets/) · [`../secrets/`](../secrets/) · [`../postgresdb/`](../postgresdb/) · [`../proxydb/`](../proxydb/) · [`../ses/`](../ses/) · [`../cognito/`](../cognito/) · [`../ssm/parameters/`](../ssm/parameters/) · [`../dynamodb/user-table/`](../dynamodb/user-table/) · [`../cloudfront/web-prod-min/`](../cloudfront/web-prod-min/). Minimal remote-state probe: [`../s3/multi-root-min/`](../s3/multi-root-min/).

**Requires Simulith** on `:4566` with S3 + DynamoDB + EC2 (VPC) + KMS + Secrets Manager + IAM + RDS (Docker sidecar) + SES + Cognito + Lambda + SSM + Route 53 + ACM + CloudFront.

## Usage (native Simulith)

From repo root:

```bash
# 0 — bootstrap (local Terraform state)
cd runtime/examples/terraform/s3/terraform-state-min
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 1 — vpc root
cd ../../multi-root-green-path/01-vpc
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 2 — subnets root (remote state env — hostname, not raw IP)
cd ../02-subnets
cp terraform.tfvars.native.example terraform.tfvars
export AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566
export AWS_ENDPOINT_URL_S3="$AWS_ENDPOINT_URL"
export AWS_ENDPOINT_URL_DYNAMODB="$AWS_ENDPOINT_URL"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=secret
export AWS_EC2_METADATA_DISABLED=true
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 3 — secrets root (same remote state env as step 2)
cd ../03-secrets
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 4 — postgresdb root (same remote state env as steps 2–3)
cd ../04-postgresdb
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 5 — proxydb root (same remote state env; requires 04-postgresdb applied first)
cd ../05-proxydb
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 6 — ses root (same remote state env for backend; standalone ses/ shape)
cd ../06-ses
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 7 — cognito root (same remote state env for backend; standalone cognito/ shape)
cd ../07-cognito
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 8 — parameters root (same remote state env; reads subnets + secrets + proxydb + cognito + ses)
cd ../08-parameters
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 9 — dynamodb root (same remote state env for backend; standalone dynamodb/ shape — parallel track)
cd ../09-dynamodb
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve

# 10 — web root (same remote state env for backend; standalone web/ shape — parallel track)
cd ../10-web
cp terraform.tfvars.native.example terraform.tfvars
terraform init -backend-config=backend.simulith.hcl
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve
```

**Windows (PowerShell)** — remote state env for steps 2–10 (use `127.0.0.1.sslip.io:4566` if `localhost` fails for virtual-hosted S3). Update `backend.simulith.hcl` endpoints to match.

```powershell
$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ENDPOINT_URL_S3 = $env:AWS_ENDPOINT_URL
$env:AWS_ENDPOINT_URL_DYNAMODB = $env:AWS_ENDPOINT_URL
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
```

**T2 helper (full eleven-step chain)** — bootstrap → `10-web` apply + reverse destroy. Requires Simulith **v0.153.0+** (Secrets Manager tags on `03-secrets`) on `:4566`.

```powershell
powershell -ExecutionPolicy Bypass -File runtime/examples/terraform/multi-root-green-path/run-t2-full-chain.ps1
# Log: runtime/examples/terraform/multi-root-green-path/t2-full-chain.log
```

**T2 evidence:** full-chain **PASS** — 2026-08-28 · v0.153.0 · ~15 min apply + destroy (all eleven steps OK).

**T2 helper** — ten-step infra + app chain (no `10-web`):

```powershell
powershell -ExecutionPolicy Bypass -File runtime/examples/terraform/multi-root-green-path/run-t2-sml295.ps1
# Log: runtime/examples/terraform/multi-root-green-path/t2-sml295.log
```

**T2 helper** — bootstrap + standalone `10-web/` apply + destroy. Requires Simulith **v0.152.0+** (Route53 + ACM + CloudFront subset) on `:4566`.

```powershell
powershell -ExecutionPolicy Bypass -File runtime/examples/terraform/multi-root-green-path/run-t2-sml299.ps1
# Log: runtime/examples/terraform/multi-root-green-path/t2-sml299.log
```

**T2 helper** — apply deps through `04-postgresdb`, then **two** applies on `05-proxydb/` (2nd apply exercises `UpdateRole`). Requires Simulith **v0.151.0+** on `:4566`.

```powershell
# From repo root after: cd runtime; go build -o simulith.exe ./cmd/simulith; .\simulith.exe start --port 4566
powershell -ExecutionPolicy Bypass -File runtime/examples/terraform/multi-root-green-path/run-t2-sml297.ps1
# Log: runtime/examples/terraform/multi-root-green-path/t2-sml297.log
```

Destroy **reverse** order: `10-web` → `09-dynamodb` → `08-parameters` → `07-cognito` → `06-ses` → `05-proxydb` → `04-postgresdb` → `03-secrets` → `02-subnets` → `01-vpc` → `terraform-state-min`.

See [`runtime/docs/terraform-integration.md`](../../../terraform-integration.md) · –013 / –038.

## Post full-chain T2

Eleven-step multi-root T2 **PASS** on **v0.153.0** (2026-08-28). Gap during chain: **** → ****. **No new P1 runtime gap** from .

**Layer 3 (bootstrap + vpc + subnets + secrets + postgresdb + proxydb + ses + cognito + parameters + dynamodb + web):** `terraformState/`; `vpc/`; `subnets/`; `secrets/` T2 **PASS**; `postgresdb/` T2 **PASS**; `proxydb/` T2 **PASS**; `ses/` T2 **PASS**; `cognito/` T2 **PASS**; `parameters/` T2 **PASS**; `dynamodb/` T2 **PASS**; `web/` T2 **PASS**. Helpers: [`run-l3-terraformState.ps1`](run-l3-terraformState.ps1), [`run-l3-vpc.ps1`](run-l3-vpc.ps1), [`run-l3-subnets.ps1`](run-l3-subnets.ps1), [`run-l3-secrets.ps1`](run-l3-secrets.ps1), [`run-l3-postgresdb.ps1`](run-l3-postgresdb.ps1), [`run-l3-proxydb.ps1`](run-l3-proxydb.ps1), [`run-l3-ses.ps1`](run-l3-ses.ps1), [`run-l3-cognito.ps1`](run-l3-cognito.ps1), [`run-l3-parameters.ps1`](run-l3-parameters.ps1), [`run-l3-dynamodb.ps1`](run-l3-dynamodb.ps1), [`run-l3-web.ps1`](run-l3-web.ps1). Gap reports: `simulith-layer3-validator-secrets-green-path/analysis.md` · `simulith-layer3-validator-postgresdb-green-path/analysis.md` · `simulith-layer3-validator-proxydb-green-path/analysis.md` · `simulith-layer3-validator-ses-green-path/analysis.md` · `simulith-layer3-validator-cognito-green-path/analysis.md` · `simulith-layer3-validator-parameters-green-path/analysis.md` · `simulith-layer3-validator-dynamodb-green-path/analysis.md` · `simulith-layer3-validator-web-green-path/analysis.md`.

**Layer 3 runbook:** `runtime/docs/prod-validator-runbook.md`. **Layer 3 complete**. **Layer 4 Serverless discovery:** `simulith-post-layer3-serverless-discovery/analysis.md`.

Gap report: .

## Post-web discovery

Generic **eleven-step** graph is complete for documented parallel tracks (infra through `10-web/`). ** closed**. Full-chain T2 **PASS**. Superseded by post-full-chain section above.

Gap report: .

## Post-web status

**`10-web/`** shipped — Route53 zone + ACM DNS validation + S3 origin (PAB + policy) + OAC + CloudFront distribution (ACM viewer cert, managed cache policy, IPv6, SPA errors) + DNS alias. Standalone parallel track; same `.tf` shape as [`cloudfront/web-prod-min/`](../cloudfront/web-prod-min/). S3 backend key `demo-web-state`.

Remaining parallel tracks: **Serverless backend** (layer 4). Layers **T2 PASS** — [`run-l4-layer-transversal.ps1`](run-l4-layer-transversal.ps1) · [`run-l4-remaining-layers.ps1`](run-l4-remaining-layers.ps1) · [`run-l4-auth-api.ps1`](run-l4-auth-api.ps1) · [`run-l4-tenant-api.ps1`](run-l4-tenant-api.ps1) · [`run-l4-transaction-api.ps1`](run-l4-transaction-api.ps1) · [`run-l4-engine-api.ps1`](run-l4-engine-api.ps1) · [`run-l4-otp-api.ps1`](run-l4-otp-api.ps1). Next: `email-api`. Discovery: `simulith-post-layer3-serverless-discovery/analysis.md`.

## Post-UpdateRole status

The generic **ten-step** infra + app chain is green through `09-dynamodb/`. Incremental **`05-proxydb` re-apply** green. ** closed** — no new P1 runtime gap from .

Gap report: .

## Post-dynamodb status

The generic **ten-step** chain is green through `09-dynamodb/`. Incremental **`05-proxydb` re-apply** green. Remaining parallel tracks: `web/`, Lambda stacks (see [`../lambda-vpc-rds/transaction-min/`](../lambda-vpc-rds/transaction-min/)).

Gap report: .

## Post-parameters status

The generic **infra + platform config** chain is green through `08-parameters/`. App roots (`dynamodb/`, Lambda stacks, `web/`) are **parallel tracks**, not downstream of parameters.

Remaining Lambda green path: [`../lambda-vpc-rds/transaction-min/`](../lambda-vpc-rds/transaction-min/).

**Post-parameters:** `05-proxydb` remote state exposes non-empty `rds_proxy_endpoint` after apply. `08-parameters/` reads proxydb remote state only — same shape as unmodified prod `parameters/`. **`09-dynamodb/`** shipped — app-table parallel track (`demoapp_user` + 2 GSIs).

Gap report (post-dynamodb): .
