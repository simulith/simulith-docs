# Cost Explorer (local estimate)

Simulith records **successful AWS API calls** against the runtime and exposes a **Cost Explorer subset** so you can compare estimated on-demand spend with real AWS billing patterns.

> **Not** your AWS invoice. Reference prices default to **us-east-1** on-demand list rates (simplified).

## Metering

- One **request unit** per successful API response (`2xx`) on AWS routes (DynamoDB, S3, Lambda, SQS, etc.).
- **Lambda invoke** also records **Lambda-GB-Second** from function memory and billed duration (100 ms granularity).
- **Usage types** vary by action (e.g. DynamoDB `PutItem` → `WriteRequestUnits`, `GetItem` → `ReadRequestUnits`, S3 GET vs PUT tiers).
- **Inventory (Fixed:*)** — daily snapshot of persisted resources (DynamoDB/S3 storage estimate, RDS instance-hours, Secrets, log groups). Refreshed on runtime start, after **seed**, and via `POST /_simulith/v1/cost/inventory/refresh`.
- Aggregated per **UTC calendar day** in SQLite (`cost_usage_daily`).
- Cleared on **`POST /_simulith/v1/reset`** with the rest of local state.

## Verify

```bash
simulith verify cost --endpoint http://127.0.0.1:4566
```

Simulith-only scenarios: `get-cost-and-usage`, `api-metering`, `inventory-refresh`.

## API

JSON **1.1** on the runtime endpoint (SigV4 service `ce`):

| Operation | Status |
| --- | --- |
| `GetCostAndUsage` | Supported — `UnblendedCost`, `UsageQuantity`, `DAILY` / `MONTHLY`, `GroupBy` `SERVICE` or `USAGE_TYPE` (one dimension per request) |
| `GetDimensionValues` | Supported — `SERVICE`, `USAGE_TYPE` |

Example:

```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-11-01,End=2026-12-01 \
  --granularity DAILY \
  --metrics UnblendedCost UsageQuantity \
  --group-by Type=DIMENSION,Key=SERVICE \
  --endpoint-url http://127.0.0.1:4566
```

## Console

**Billing** (`/billing`) — presets: Today, Last 7 days, Last 30 days, This month; historical months from `GET /_simulith/v1/cost/months`.

## Admin

- `GET /_simulith/v1/cost/months` — distinct `YYYY-MM` months with usage data.
