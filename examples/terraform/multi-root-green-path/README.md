# Production multi-root green path — vpc → subnets → secrets → postgresdb → proxydb → ses → cognito → parameters → dynamodb (Simulith)

Generic **ten-step** graph matching production apply order with S3 remote state between roots. Names are `demoapp` / `demo-terraform-state`.

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
```

Single-root twins: [`../vpc-root/`](../vpc-root/) · [`../subnets/`](../subnets/) · [`../secrets/`](../secrets/) · [`../postgresdb/`](../postgresdb/) · [`../proxydb/`](../proxydb/) · [`../ses/`](../ses/) · [`../cognito/`](../cognito/) · [`../ssm/parameters/`](../ssm/parameters/) · [`../dynamodb/user-table/`](../dynamodb/user-table/). Minimal remote-state probe: [`../s3/multi-root-min/`](../s3/multi-root-min/).

**Requires Simulith** on `:4566` with S3 + DynamoDB + EC2 (VPC) + KMS + Secrets Manager + IAM + RDS (Docker sidecar) + SES + Cognito + Lambda + SSM.

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
```

**Windows (PowerShell)** — remote state env for steps 2–9 (use `127.0.0.1.sslip.io:4566` if `localhost` fails for virtual-hosted S3). Update `backend.simulith.hcl` endpoints to match.

```powershell
$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ENDPOINT_URL_S3 = $env:AWS_ENDPOINT_URL
$env:AWS_ENDPOINT_URL_DYNAMODB = $env:AWS_ENDPOINT_URL
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
```

Destroy **reverse** order: `09-dynamodb` → `08-parameters` → `07-cognito` → `06-ses` → `05-proxydb` → `04-postgresdb` → `03-secrets` → `02-subnets` → `01-vpc` → `terraform-state-min`.

See [`runtime/docs/terraform-integration.md`](../../../terraform-integration.md) · –013 / –034.

## Post-dynamodb status

The generic **ten-step** chain is green through `09-dynamodb/`. Remaining parallel tracks: `web/`, Lambda stacks (see [`../lambda-vpc-rds/transaction-min/`](../lambda-vpc-rds/transaction-min/)).

**Next runtime gap:** incremental `05-proxydb` re-apply fails on `UpdateRole` — full destroy+apply workaround only today.

Gap report: .

## Post-parameters status

The generic **infra + platform config** chain is green through `08-parameters/`. App roots (`dynamodb/`, Lambda stacks, `web/`) are **parallel tracks**, not downstream of parameters.

Remaining Lambda green path: [`../lambda-vpc-rds/transaction-min/`](../lambda-vpc-rds/transaction-min/).

**Post-parameters:** `05-proxydb` remote state exposes non-empty `rds_proxy_endpoint` after apply. `08-parameters/` reads proxydb remote state only — same shape as unmodified prod `parameters/`. **`09-dynamodb/`** shipped — app-table parallel track (`demoapp_user` + 2 GSIs).

Gap report (post-dynamodb): . **** (`UpdateRole`) ships in  for incremental `05-proxydb` re-apply.
