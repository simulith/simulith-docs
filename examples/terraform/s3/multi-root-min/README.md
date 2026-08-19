# S3 multi-root-min — remote state between Terraform roots

Generic **three-root** graph against Simulith. Names are `demo-*` / `demoapp`. Method bar from **** plus overlay-free remote state: apply a downstream root whose state lives in S3, then a second root that **reads** that state with `terraform_remote_state` (no `endpoints` in the data source).

```text
terraform-state-min/     local state → versioned bucket + lock table
01-network/              backend "s3" → aws_vpc, key demo-network-state
02-dependent/            backend "s3" + data.terraform_remote_state → security group
```

Not a copy of any customer tree. VPC completeness stays in [`vpc/network-min/`](../../vpc/network-min/).

**Requires Simulith** on `:4566` (or Console `:9080/runtime`) with S3 + DynamoDB + EC2 (VPC).

## Usage

From the repo root, with Simulith on `:4566`:

```bash
# 0 — bootstrap (local Terraform state)
cd runtime/examples/terraform/s3/terraform-state-min
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply

# 1 — network root stores state in that bucket
cd ../multi-root-min/01-network
cp terraform.tfvars.native.example terraform.tfvars
terraform init \
  -backend-config="endpoints={s3=\"http://127.0.0.1:4566\",dynamodb=\"http://127.0.0.1:4566\"}" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=secret"
terraform apply

# 2 — dependent root reads vpc_id from remote state (env, not in-file endpoints)
cd ../02-dependent
cp terraform.tfvars.native.example terraform.tfvars
# Hostname, not a raw IP: Terraform virtual-hosts <bucket>.<host> when use_path_style is unset.
export AWS_ENDPOINT_URL=http://localhost:4566
# Windows (*.localhost often does not resolve):
# export AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566
export AWS_ENDPOINT_URL_S3="$AWS_ENDPOINT_URL"
export AWS_ENDPOINT_URL_DYNAMODB="$AWS_ENDPOINT_URL"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=secret
export AWS_EC2_METADATA_DISABLED=true
terraform init \
  -backend-config="endpoints={s3=\"$AWS_ENDPOINT_URL\",dynamodb=\"$AWS_ENDPOINT_URL\"}" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=secret"
terraform apply
```

Destroy **reverse** order: `02-dependent` → `01-network` → `terraform-state-min`. Versioned bucket empty uses **ListObjectVersions**.

Automated smoke: `maintainer workflow (private monorepo)`

## Allowed delta (endpoint / creds)

| Surface | First-party example | Unmodified production root |
| --- | --- | --- |
| `backend "s3"` | `-backend-config` at `init` (no endpoints in `.tf`) | same |
| AWS provider | `use_simulith_endpoint` | gitignored `*_override.tf` with `endpoints { … }` |
| `data.terraform_remote_state` | Env for **endpoints** (`AWS_ENDPOINT_URL` / `_S3` / `_DYNAMODB` + creds) on a **hostname** (`localhost` or `127.0.0.1.sslip.io`). STS `GetCallerIdentity` is stubbed. **No `endpoints`, skip_*, or `use_path_style` in `.tf`.** `-backend-config` does **not** apply. | same env; hostname (not a raw IP) so virtual-hosted DNS works |

## Honest limits

- Object writes keep **one current version** per key (overwrite replaces the version ID) — Terraform state still round-trips via PutObject/GetObject.
- `terraform_remote_state` needs a **hostname** endpoint (`localhost` / `127.0.0.1.sslip.io`), not `127.0.0.1`. There is no HashiCorp env for `use_path_style`. STS skip flags are gone; path-style in the data source is gone.
- Gateway / interface VPC endpoints, NAT traffic, 6-AZ layouts: not this module — **/021**, `network-min`.
- This is not “Simulith = AWS hardware.” It is the **same Terraform graph shape** with endpoint/creds injection.
