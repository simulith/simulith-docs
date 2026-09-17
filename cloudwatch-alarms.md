# CloudWatch Alarms — Simulith

Local **CloudWatch metric alarms** emulation (definition CRUD only — not automatic evaluation or SNS actions).

## Overview

- **SigV4 service name:** `monitoring` (same endpoint as [CloudWatch Metrics](cloudwatch-metrics.md))
- **Protocol:** AWS Query (`application/x-www-form-urlencoded`)
- **API version:** `2010-08-01`
- **Same port** as other services (default `:4566`)

Compatible with AWS CLI (`aws cloudwatch put-metric-alarm`, `describe-alarms`, `delete-alarms`) when using `--endpoint-url http://localhost:4566`.

## What you can do

| Operation | Notes |
| --- | --- |
| `PutMetricAlarm` | Create or update a threshold alarm definition |
| `DescribeAlarms` | List alarms; optional `AlarmNames` filter |
| `DeleteAlarms` | Delete alarms by name |

## What Simulith does not do

| Area | Notes |
| --- | --- |
| Alarm evaluation / state transitions | Alarms stay `INSUFFICIENT_DATA` until a future story evaluates metrics |
| `SetAlarmState`, composite alarms, anomaly detectors |  remainder |
| Dashboards |  |
| SNS / action execution | Action ARNs are stored but not invoked |

## Persistence

Alarm definitions are stored in SQLite (`cloudwatch_alarms`). Cleared on `simulith reset`.

## Verify

```bash
simulith verify cloudwatch-alarms --skip-aws   # CI smoke (Simulith-only)
simulith verify cloudwatch-alarms              # full parity vs AWS sandbox (P-dev)
```

Scenarios: `put-describe-alarms`, `delete-alarms`.

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws cloudwatch put-metric-alarm --alarm-name cpu-high \
  --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
  --period 300 --evaluation-periods 1 --threshold 80 \
  --comparison-operator GreaterThanThreshold --endpoint-url "$EP"

aws cloudwatch describe-alarms --alarm-names cpu-high --endpoint-url "$EP"

aws cloudwatch delete-alarms --alarm-names cpu-high --endpoint-url "$EP"
```

## Terraform

Green path: [`examples/terraform/cloudwatch-alarms/`](examples/terraform/cloudwatch-alarms/) — `aws_cloudwatch_metric_alarm` apply + destroy with `endpoints { cloudwatch }`. See [terraform-integration.md](terraform-integration.md).

## Related

See also [cloudwatch-metrics.md](cloudwatch-metrics.md) · [cloudwatch.md](cloudwatch.md) (Logs).
