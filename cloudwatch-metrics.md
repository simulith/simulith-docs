# CloudWatch Metrics — Simulith

Local **CloudWatch Metrics** emulation (custom metrics only — not Logs, Alarms, or Dashboards).

## Overview

- **SigV4 service name:** `monitoring`
- **Protocol:** AWS Query (`application/x-www-form-urlencoded`)
- **API version:** `2010-08-01`
- **Same port** as other services (default `:4566`)

Compatible with AWS CLI (`aws cloudwatch`) when using `--endpoint-url http://localhost:4566`.

## Supported operations

| Operation | Status |
| --- | --- |
| PutMetricData | ✓ |
| ListMetrics | ✓ |
| GetMetricStatistics | ✓ |

## Limits

| Area | Notes |
| --- | --- |
| GetMetricData, Alarms, Dashboards | + |
| Metric streams, anomaly detectors | Not emulated |
| Cross-account / cross-region | Single local account/region |

## Persistence

Datapoints stored in SQLite (`cloudwatch_metric_datapoints`). Cleared on `simulith reset`.

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws cloudwatch put-metric-data --namespace Simulith/Demo --metric-name Latency \
  --value 120 --unit Milliseconds --endpoint-url "$EP"

aws cloudwatch list-metrics --namespace Simulith/Demo --endpoint-url "$EP"

aws cloudwatch get-metric-statistics --namespace Simulith/Demo --metric-name Latency \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) --period 60 --statistics Average \
  --endpoint-url "$EP"
```

See also [cloudwatch.md](cloudwatch.md) (Logs).
