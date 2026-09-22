# CloudWatch Dashboards — Simulith

Local **CloudWatch dashboard** definitions (CRUD + persistence — no widget rendering).

## Overview

- **SigV4 service name:** `monitoring` (same endpoint as [CloudWatch Metrics](cloudwatch-metrics.md))
- **Protocol:** AWS Query (`application/x-www-form-urlencoded`)
- **API version:** `2010-08-01`
- **Same port** as other services (default `:4566`)

Compatible with AWS CLI (`aws cloudwatch put-dashboard`, `get-dashboard`, `list-dashboards`, `delete-dashboards`) when using `--endpoint-url http://localhost:4566`.

## What you can do

| Operation | Notes |
| --- | --- |
| `PutDashboard` | Create or update a dashboard; stores `DashboardBody` JSON as opaque text |
| `GetDashboard` | Fetch dashboard by name; returns `DashboardArn`, `DashboardBody`, `LastModified` |
| `ListDashboards` | List dashboards; optional `DashboardNamePrefix` filter |
| `DeleteDashboards` | Delete dashboards by name |

## What Simulith does not do

| Area | Notes |
| --- | --- |
| Widget rendering / live metric queries from dashboard body | Body stored only |
| Dashboard JSON schema validation | Any non-empty string accepted |
| Console widget rendering | Body displayed as JSON only |
| Cross-account sharing, tags | Not emulated |

## Verify

```bash
simulith verify cloudwatch-dashboards --skip-aws   # CI smoke (Simulith-only)
simulith verify cloudwatch-dashboards              # full parity vs AWS sandbox (P-dev)
```

Scenarios: `put-get-dashboard`, `list-dashboards`, `delete-dashboards`.

## Terraform

Green path: [`examples/terraform/cloudwatch-dashboards/`](examples/terraform/cloudwatch-dashboards/) — `terraform apply` and `terraform destroy` with `-parallelism=1`.

## Persistence

Dashboard definitions are stored in SQLite (`cloudwatch_dashboards`). Cleared on `simulith reset`.

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws cloudwatch put-dashboard \
  --endpoint-url "$EP" \
  --dashboard-name demo-dashboard \
  --dashboard-body '{"widgets":[]}'

aws cloudwatch get-dashboard --endpoint-url "$EP" --dashboard-name demo-dashboard
aws cloudwatch list-dashboards --endpoint-url "$EP"
aws cloudwatch delete-dashboards --endpoint-url "$EP" --dashboard-names demo-dashboard
```

## Console

Open **CloudWatch → Dashboards** in the local Console ([console.md](console.md)) — read-only **ListDashboards** + **GetDashboard** with JSON body viewer.

## Related

- [CloudWatch Metrics](cloudwatch-metrics.md)
- [CloudWatch Alarms](cloudwatch-alarms.md)
- [compatibility-matrix.md](compatibility-matrix.md)
