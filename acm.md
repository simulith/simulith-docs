# ACM (AWS Certificate Manager)

Simulith implements a **minimal DNS-validated certificate slice** for web-stack Terraform and CLI workflows.

## Protocol

- **Endpoint:** same as runtime (`http://127.0.0.1:4566` by default)
- **Content-Type:** `application/x-amz-json-1.1`
- **X-Amz-Target:** `CertificateManager.<Operation>`
- **SigV4 signing name:** `acm`

## Implemented operations

| Operation | Notes |
| --- | --- |
| `RequestCertificate` | DNS validation only; `ClientToken` / `IdempotencyToken` idempotency |
| `DescribeCertificate` | Returns domain, status, validation options |
| `ListCertificates` | Optional status filter |
| `DeleteCertificate` | For Terraform destroy |
| `ListTagsForCertificate` | Empty tag list stub (Terraform read) |

## Behaviour notes

- **Local validation stub** — first `DescribeCertificate` or `ListCertificates` flips `PENDING_VALIDATION` → `ISSUED`; Simulith does **not** contact a real CA or DNS resolver.
- **DomainValidationOptions** include CNAME record names/values for Route 53 workflows — create records in a hosted zone or use the Terraform green path.
- **Email validation, imported certs, private CA, and cross-region replication** are out of scope.

## Terraform

Green path: [`examples/terraform/acm/cert-min/`](examples/terraform/acm/cert-min/) — hosted zone + certificate + DNS validation records + `aws_acm_certificate_validation`; `terraform apply` and **`terraform destroy`** with `-parallelism=1`.

```hcl
provider "aws" {
  endpoints {
    acm     = "http://127.0.0.1:4566"
    route53 = "http://127.0.0.1:4566"
  }
  skip_credentials_validation = true
  # ...
}
```

## Backlog

See .

## Seed

Default fixture includes DNS-validated certificate for **`demo.simulith.local`** (SAN **`www.demo.simulith.local`**) with fixed ARN **`arn:aws:acm:us-east-1:000000000000:certificate/22222222-2222-4222-8222-222222222222`** — status **ISSUED** after seed. See [seed.md](seed.md).

## Console

Panel **`/acm`**: list certificates, request DNS-validated cert, describe metadata and validation options. See [console.md](console.md).

## Verify

```bash
simulith verify acm --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify acm                     # AWS parity (RequestCertificate, DescribeCertificate)
simulith verify acm --filter certificate  # subset by scenario name prefix
```

Scenarios: `certificate-request-describe-list`, `certificate-client-token-idempotency`.
