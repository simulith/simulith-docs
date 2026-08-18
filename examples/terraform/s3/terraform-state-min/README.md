# S3 terraform-state-min — remote-state bootstrap

Versioned S3 bucket (SSE-S3, public access block, lifecycle) + DynamoDB lock table. Apply this first; later roots `terraform init` with `backend "s3"` against the bucket.

**Requires Simulith** with Put/Get versioning, encryption, lifecycle, and tagging.

## Usage

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply
```

Prove a child root can init against that backend:

```bash
cd backend-probe
terraform init \
  -backend-config="endpoints={s3=\"http://127.0.0.1:4566\",dynamodb=\"http://127.0.0.1:4566\"}" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=secret"
```

```bash
terraform destroy
```

Automated smoke: `maintainer workflow (private monorepo)`

Downstream apply that **writes** and **reads** remote state: [`../multi-root-min/`](../multi-root-min/) (`s3-multi-root-min`).

## Honest limits

- Versioning **status** is persisted; objects stay last-write-wins (no `ListObjectVersions`).
- SSE-S3 is metadata; objects are not encrypted on disk.
- Lifecycle rules are stored and returned; they do not expire objects.
- AWS provider v5 waits ~1 minute after PutBucketLifecycle (10 consecutive matching GETs). Apply is not hung unless it exceeds ~3 minutes.
