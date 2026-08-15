# CloudFront cdn-min — Terraform green path

Minimal **web-stack CDN** subset: S3 origin + Origin Access Control + CloudFront distribution + Route 53 CNAME against Simulith.

## Resources

| Terraform | Simulith API |
| --- | --- |
| `aws_s3_bucket` + `aws_s3_object` | CreateBucket, PutObject, DeleteObject, DeleteBucket |
| `aws_cloudfront_origin_access_control` | CreateOriginAccessControl, GetOriginAccessControl, DeleteOriginAccessControl |
| `aws_cloudfront_distribution` | CreateDistribution, GetDistribution, GetDistributionConfig, UpdateDistribution, DeleteDistribution |
| `aws_route53_zone` | CreateHostedZone, DeleteHostedZone |
| `aws_route53_record` (CNAME) | ChangeResourceRecordSets |

## Usage

```bash
cp terraform.tfvars.native.example terraform.tfvars   # or .example for all-in-one :9080/runtime
terraform init
terraform apply -parallelism=1
terraform destroy -parallelism=1
```

**Endpoint:** set `simulith_endpoint` to your runtime URL (`http://127.0.0.1:4566` native, `http://127.0.0.1:9080/runtime` all-in-one). Requires **Simulith v0.106.1+** for full apply/destroy green path (v0.106.0+ for CreateDistribution).

**Green path E2E (web/CDN subset):** S3 bucket + object → OAC → distribution → Route 53 zone + `cdn` CNAME. For ACM viewer cert + alias, use [`web-prod-min/`](../web-prod-min/).

Automated smoke: `maintainer workflow (private monorepo)`
