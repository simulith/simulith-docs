# Production multi-root green path — vpc → subnets → secrets → postgresdb (Simulith)

Generic **five-step** graph matching production apply order with S3 remote state between roots. Names are `demoapp` / `demo-terraform-state`.

```text
terraform-state-min/           local state → versioned bucket + lock table
multi-root-green-path/
  01-vpc/                      backend "s3" → production vpc/ shape (7 resources)
  02-subnets/                  backend "s3" + terraform_remote_state → subnets/ shape (12 resources)
  03-secrets/                  backend "s3" + terraform_remote_state → secrets/ shape (6 resources)
  04-postgresdb/               backend "s3" + terraform_remote_state → postgresdb/ shape (4 resources)
```

Single-root twins: [`../vpc-root/`](../vpc-root/) · [`../subnets/`](../subnets/) · [`../secrets/`](../secrets/) · [`../postgresdb/`](../postgresdb/). Minimal remote-state probe: [`../s3/multi-root-min/`](../s3/multi-root-min/).

**Requires Simulith** on `:4566` with S3 + DynamoDB + EC2 (VPC) + KMS + Secrets Manager + RDS (Docker sidecar).

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
```

**Windows (PowerShell)** — remote state env for steps 2–4 (use `127.0.0.1.sslip.io:4566` if `localhost` fails for virtual-hosted S3). Update `backend.simulith.hcl` endpoints to match.

```powershell
$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ENDPOINT_URL_S3 = $env:AWS_ENDPOINT_URL
$env:AWS_ENDPOINT_URL_DYNAMODB = $env:AWS_ENDPOINT_URL
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
```

Destroy **reverse** order: `04-postgresdb` → `03-secrets` → `02-subnets` → `01-vpc` → `terraform-state-min`.

See [`runtime/docs/terraform-integration.md`](../../../terraform-integration.md) · –013 /  /  / .
