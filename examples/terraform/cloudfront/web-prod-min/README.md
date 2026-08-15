# CloudFront web-prod-min — Terraform green path

**Web/CDN prod subset:** S3 origin + OAC + ACM viewer certificate + CloudFront distribution with alias + Route 53 DNS validation and CNAME — apply/destroy against Simulith.

Extends [`cdn-min/`](../cdn-min/) (default CloudFront cert) with patterns from [`acm/cert-min/`](../../acm/cert-min/) (zone + cert + validation).

## Resources

| Terraform | Simulith API |
| --- | --- |
| `aws_route53_zone` | CreateHostedZone, DeleteHostedZone |
| `aws_acm_certificate` + `aws_acm_certificate_validation` | RequestCertificate, DescribeCertificate, DeleteCertificate |
| `aws_route53_record` (validation) | ChangeResourceRecordSets |
| `aws_s3_bucket` + `aws_s3_object` | CreateBucket, PutObject, DeleteObject, DeleteBucket |
| `aws_s3_bucket_public_access_block` | PutPublicAccessBlock, GetPublicAccessBlock |
| `aws_s3_bucket_policy` | PutBucketPolicy, GetBucketPolicy, DeleteBucketPolicy |
| `aws_cloudfront_origin_access_control` | CreateOriginAccessControl, DeleteOriginAccessControl |
| `aws_cloudfront_distribution` (aliases + ACM viewer cert) | CreateDistribution, UpdateDistribution, DeleteDistribution |
| `aws_route53_record` (CNAME or apex A alias) | ChangeResourceRecordSets |

## Usage

```bash
cp terraform.tfvars.native.example terraform.tfvars   # or .example for all-in-one :9080/runtime
terraform init
terraform apply -parallelism=1
terraform destroy -parallelism=1
```

**Endpoint:** set `simulith_endpoint` to your runtime URL. Requires **Simulith v0.109.1+** (S3 bucket policy/PAB + Route 53 alias A for apex).

**DNS:** set `domain_name` equal to `zone_name` for apex **A alias**; otherwise a subdomain **CNAME** is created (default `cdn.<zone>`).

Automated smoke: `maintainer workflow (private monorepo)`
