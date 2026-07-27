# Terraform — S3 → Lambda notification

Cross-service pattern: **S3 bucket notification** on `ObjectCreated` invokes a **Lambda** function asynchronously when objects are uploaded under prefix `in/`.

**Source pattern:** [AWS S3 event notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html) + [Using AWS Lambda with Amazon S3](https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html).

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md)) with /162
- Terraform ≥ 1.6, AWS provider ~> 5.x
- **Node.js** on PATH

## Apply (Simulith)

```bash
cd runtime/examples/terraform/s3-lambda
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -parallelism=1
```

Expected plan: **3 to add** (bucket, Lambda, bucket notification).

## Verify dispatch (manual)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

echo "terraform test" | aws s3api put-object \
  --bucket "$(terraform output -raw bucket_name)" \
  --key "$(terraform output -raw upload_key)" \
  --body - \
  --endpoint-url "$AWS_ENDPOINT"

# Handler writes MARKER_DIR/{key}.done — see outputs.marker_dir
ls "$(terraform output -raw marker_dir)"/*.done
```

## Destroy

```bash
terraform destroy -parallelism=1
```

## Simulith limits

- No `aws_lambda_permission` — Simulith skips S3 service principal checks
- Lambda notification targets only
- `MARKER_DIR` is a local verification aid (see CLI README)
- `s3_use_path_style = true` on Simulith provider

## Related

- AWS CLI flow: [`../../aws-cli/s3-lambda/`](../../aws-cli/s3-lambda/)
- S3 green path: [`../s3/`](../s3/)
- [s3.md](../../../s3.md) · [lambda.md](../../../lambda.md)
- [terraform-integration.md — Honest integration examples](../../../terraform-integration.md#honest-integration-examples)
