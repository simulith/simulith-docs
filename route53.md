# Route 53 (DNS)

Simulith implements a **minimal hosted-zone slice** for local Terraform and CLI DNS workflows.

## Protocol

- **Endpoint:** same as runtime (`http://127.0.0.1:4566` by default)
- **API version:** `2013-04-01`
- **Formats:** AWS SDK uses **REST/XML** (`/2013-04-01/hostedzone/...`); AWS CLI may use JSON 1.1 targets
- **SigV4 signing name:** `route53`

## Implemented operations

| Operation | Notes |
| --- | --- |
| `CreateHostedZone` | Public zones; idempotent on `CallerReference` |
| `ListHostedZones` | Full list (no pagination) |
| `GetHostedZone` | Zone metadata + delegation set stub |
| `DeleteHostedZone` | Empty zones only (non-required RRsets must be removed first) |
| `ChangeResourceRecordSets` | **A** and **CNAME** — CREATE / UPSERT / DELETE |
| `ListResourceRecordSets` | Optional `StartRecordName` / `StartRecordType` filter |
| `GetChange` | Returns `INSYNC` stub |

## Behaviour notes

- **Local DNS stub** — records are stored in SQLite for Terraform/CLI/Console; Simulith does **not** serve real DNS queries.
- **Record types** — A and CNAME only in the initial slice; alias records, weighted/latency/geo routing, health checks, and DNSSEC are out of scope.
- **Delegation set** — fixed stub name servers in create/get responses (not resolvable locally).
- **Private hosted zones** — metadata flag only; no VPC association.

## Terraform

Green path: [`examples/terraform/route53/zone-min/`](examples/terraform/route53/zone-min/) — hosted zone + A/CNAME records; `terraform apply` + **`terraform destroy`** with `-parallelism=1`.

```hcl
provider "aws" {
  endpoints { route53 = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
  # ...
}
```

## Backlog

See .

## Seed

Default fixture includes hosted zone **`demo.simulith.local`** with **`www`** A → `127.0.0.1` and **`cdn`** CNAME → `www.demo.simulith.local`. See [seed.md](seed.md).

## Console

Panel **`/route53`**: list zones, create zone, UPSERT A record. See [console.md](console.md).

## Verify

```bash
simulith verify route53 --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify route53                     # AWS parity (CreateHostedZone, ListHostedZones, ChangeResourceRecordSets)
simulith verify route53 --filter hosted-zone  # subset by scenario name prefix
```

Scenarios: `hosted-zone-record-lifecycle` (CreateHostedZone, ListHostedZones, A record CREATE), `cname-record-upsert` (CNAME CREATE).
