# ACM cert-min — Terraform green path

Minimal **web-stack TLS** subset: hosted zone + ACM certificate + DNS validation records against Simulith.

## Resources

| Terraform | Simulith API |
| --- | --- |
| `aws_route53_zone` | CreateHostedZone, DeleteHostedZone |
| `aws_acm_certificate` | RequestCertificate, DescribeCertificate, DeleteCertificate |
| `aws_route53_record` (validation) | ChangeResourceRecordSets |
| `aws_acm_certificate_validation` | DescribeCertificate waiter (local DNS validation stub → ISSUED) |

## Usage

```bash
cp terraform.tfvars.native.example terraform.tfvars   # or .example for all-in-one :9080/runtime
terraform init
terraform apply -parallelism=1
terraform destroy -parallelism=1
```

**Endpoint:** set `simulith_endpoint` to your runtime URL (`http://127.0.0.1:4566` native, `http://127.0.0.1:9080/runtime` all-in-one).

Automated smoke: `maintainer workflow (private monorepo)`
