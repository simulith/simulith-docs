# CloudFront (Amazon CloudFront)

Simulith implements a **minimal CloudFront slice** for local web-stack Terraform: Origin Access Control, distributions (including ACM viewer certificates), and Route 53 DNS.

## Protocol

- **Endpoint:** same as runtime (`http://127.0.0.1:4566` by default)
- **REST/XML paths:** `/2020-05-31/origin-access-control`, `/2020-05-31/distribution`
- **SigV4 signing name:** `cloudfront` (region `us-east-1`)

## Implemented operations

| Operation | Notes |
| --- | --- |
| `CreateOriginAccessControl` | S3 OAC subset |
| `GetOriginAccessControl` | By OAC id |
| `CreateDistribution` | S3 origin + OAC ref; status **Deployed** immediately |
| `GetDistribution` | Returns ETag header + config |
| `GetDistributionConfig` | Config-only read for Terraform refresh |
| `UpdateDistribution` | Disable-on-destroy path; ETag / If-Match |
| `DeleteDistribution` | Terraform destroy |
| `DeleteOriginAccessControl` | Terraform destroy |
| `ListDistributions` | Summary list for Terraform refresh |

## Terraform green path

Module [`examples/terraform/cloudfront/cdn-min/`](examples/terraform/cloudfront/cdn-min/) — S3 + OAC + distribution + Route 53 CNAME. Module [`web-prod-min/`](examples/terraform/cloudfront/web-prod-min/) adds ACM viewer certificates, S3 public access block + bucket policy, and apex **A alias** (Simulith **v0.109.1+**). Use `-parallelism=1` and provider `endpoints { s3, cloudfront, route53, acm }` where needed. See [terraform-integration.md](terraform-integration.md#green-path-iac).

## Behaviour notes

- **Local CDN stub** — no edge caching or real CloudFront POP; distribution metadata only.
- **Status Deployed** on create (no InProgress wait).

## Verify

```bash
simulith verify cloudfront --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify cloudfront                     # OAC AWS parity + Simulith distribution smoke
simulith verify cloudfront --filter oac        # subset by scenario name prefix
```

Scenarios: `oac-create-get`, `distribution-oac-lifecycle`.

## Console

Panel **`/cloudfront`**: list distributions, get distribution + OAC metadata, create OAC and distribution. See [console.md](console.md).

## Seed

Default **`simulith seed`** includes OAC **`E0DEMOOAC00001`** (`demo-cdn-oac`) and distribution **`E0DEMOCF00001`** with domain **`d0democdn00001.cloudfront.net`**, S3 origin **`demo-bucket`**, and Route 53 **`cdn.demo.simulith.local`** CNAME → distribution domain. See [seed.md](seed.md).
