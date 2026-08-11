# Route 53 zone-min — Terraform green path

Minimal **web-stack DNS** subset: hosted zone + `A` + `CNAME` records against Simulith.

## Resources

| Terraform | Simulith API |
| --- | --- |
| `aws_route53_zone` | CreateHostedZone, GetHostedZone, DeleteHostedZone |
| `aws_route53_record` (×2) | ChangeResourceRecordSets (CREATE/DELETE), ListResourceRecordSets |

## Usage

```bash
cp terraform.tfvars.native.example terraform.tfvars   # or .example for all-in-one :9080/runtime
terraform init
terraform apply -parallelism=1
terraform destroy -parallelism=1
```

**Endpoint:** set `simulith_endpoint` to your runtime URL (`http://127.0.0.1:4566` native, `http://127.0.0.1:9080/runtime` all-in-one).

Automated smoke: `maintainer workflow (private monorepo)`
