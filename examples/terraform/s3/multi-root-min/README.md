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
export AWS_ENDPOINT_URL=http://127.0.0.1:4566
export AWS_ENDPOINT_URL_S3="$AWS_ENDPOINT_URL"
export AWS_ENDPOINT_URL_DYNAMODB="$AWS_ENDPOINT_URL"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=secret
export AWS_EC2_METADATA_DISABLED=true
terraform init \
  -backend-config="endpoints={s3=\"http://127.0.0.1:4566\",dynamodb=\"http://127.0.0.1:4566\"}" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=secret"
terraform apply
```

Destroy **reverse** order: `02-dependent` → `01-network`. Leave `terraform-state-min` in place unless you empty the bucket first — `force_destroy` on a versioned bucket calls `ListObjectVersions` (**FW-S3-024**), so bootstrap destroy is not green (same as `terraform-state-min` itself).

Automated smoke: `maintainer workflow (private monorepo)`

## Allowed delta (endpoint / creds)

| Surface | First-party example | Unmodified production root |
| --- | --- | --- |
| `backend "s3"` | `-backend-config` at `init` (no endpoints in `.tf`) | same |
| AWS provider | `use_simulith_endpoint` | gitignored `*_override.tf` with `endpoints { … }` |
| `data.terraform_remote_state` | Env for **endpoints** (`AWS_ENDPOINT_URL` / `_S3` / `_DYNAMODB` + creds). STS `GetCallerIdentity` is stubbed (no skip_*). Leftover overlay: `use_path_style` (IP hosts). `-backend-config` does **not** apply. | same env; leftover `use_path_style` via gitignored override if the data source has none |

## Honest limits

- Object writes are last-write-wins (no version IDs) — **FW-S3-024**. Terraform state still round-trips via PutObject/GetObject.
- `terraform_remote_state` still needs `use_path_style` locally (no HashiCorp env; `127.0.0.1` virtual-hosted DNS). STS skip flags are gone.
- Gateway / interface VPC endpoints, NAT traffic, 6-AZ layouts: not this module — **/021**, `network-min`.
- This is not “Simulith = AWS hardware.” It is the **same Terraform graph shape** with endpoint/creds injection.
