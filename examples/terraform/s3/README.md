# Terraform — S3 on Simulith and AWS

`aws_s3_bucket` + `aws_s3_object` **apply** and **destroy** work on Simulith and real AWS (provider calls **CreateBucket**, **PutObject**, **HeadObject**, **DeleteObject**, **DeleteBucket**).

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x
- AWS credentials configured for real AWS apply

## Workspaces and var-files

Use **workspaces** to isolate Terraform **state**. Use **var-files** to pick Simulith vs AWS endpoint.

| Target | Workspace | Var file | Bucket name (default) |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `app-assets-tf` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | `simulith-dev-app-assets-tf` |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

> **Pitfall:** `terraform workspace select aws` + bare `terraform apply` still auto-loads **`terraform.tfvars`** (Simulith). Always pass `-var-file=terraform.aws-dev.tfvars` for AWS.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

CLI and Console must use the **same** runtime. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/s3
cp terraform.tfvars.example terraform.tfvars   # once
terraform init
terraform workspace select default
terraform apply
```

Expected plan: **3 to add** (1 bucket + 2 objects).

**Destroy (Simulith):**

```bash
terraform workspace select default
terraform destroy
```

`force_destroy = true` on the bucket clears all objects before deleting it.
Expected plan: **3 to destroy**.

## Apply (real AWS dev)

> **Note:** bucket names must be globally unique. The example uses `simulith-dev-app-assets-tf` — rename if needed.

```bash
terraform workspace select -or-create aws
cp terraform.aws-dev.tfvars.example terraform.aws-dev.tfvars   # once; edit bucket_name if needed
terraform apply -var-file=terraform.aws-dev.tfvars
terraform destroy -var-file=terraform.aws-dev.tfvars
```

## Manual test (AWS CLI — Simulith)

After apply:

```bash
export AWS_ENDPOINT=http://127.0.0.1:9080/runtime
export AWS_DEFAULT_REGION=us-east-1

aws s3api list-buckets --endpoint-url "$AWS_ENDPOINT"
aws s3api list-objects-v2 --bucket app-assets-tf --endpoint-url "$AWS_ENDPOINT"
aws s3api get-object --bucket app-assets-tf --key config/app.json /tmp/app.json --endpoint-url "$AWS_ENDPOINT"
cat /tmp/app.json
```

## Resources created

| Resource | Type | Key / Name |
| --- | --- | --- |
| `aws_s3_bucket.app` | Bucket | `app-assets-tf` |
| `aws_s3_object.config` | Object | `config/app.json` (JSON) |
| `aws_s3_object.readme` | Object | `docs/README.md` (Markdown) |

## Limitations

- Single-part objects only (no multipart upload)
- `s3_use_path_style = true` is required when pointing Terraform at Simulith
- [s3.md](../../../s3.md) — MVP deviations

## Related

- **Object lifecycle CLI:** [`../../aws-cli/s3/`](../../aws-cli/s3/) — put/head/get/list/copy/delete-objects
- [terraform-integration.md](../../../terraform-integration.md)
- [s3.md](../../../s3.md)
- [compatibility-matrix.md](../../../compatibility-matrix.md#s3)
