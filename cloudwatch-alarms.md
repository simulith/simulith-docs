# CloudWatch Alarms — Simulith

Local **CloudWatch metric alarms** emulation with **metric-based evaluation**. SNS actions are stored but not invoked.

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
| `DescribeAlarms` | List alarms; optional `AlarmNames` filter; re-evaluates state before respond |
| `DeleteAlarms` | Delete alarms by name |

## Evaluation

When **`PutMetricData`** publishes datapoints for a metric referenced by an alarm, Simulith evaluates the alarm using **`GetMetricStatistics`** over the configured `Period` × `EvaluationPeriods` window. Matching alarms transition to:

| State | When |
| --- | --- |
| `ALARM` | All evaluation periods breach the threshold |
| `OK` | All periods have data and at least one period is not breaching |
| `INSUFFICIENT_DATA` | Not enough datapoints in the window (including after create) |

Evaluation also runs on **`DescribeAlarms`** so CLI and Console show current state without a separate poll API.

Supported comparison operators: `GreaterThanThreshold`, `GreaterThanOrEqualToThreshold`, `LessThanThreshold`, `LessThanOrEqualToThreshold`. Statistics: `Average`, `Sum`, `Minimum`, `Maximum`, `SampleCount`.

## What Simulith does not do

| Area | Notes |
| --- | --- |
| SNS / action execution | Action ARNs are stored but not invoked |
| `SetAlarmState`, composite alarms, anomaly detectors |  remainder |
| Dashboards |  |

## Persistence

Alarm definitions are stored in SQLite (`cloudwatch_alarms`). Cleared on `simulith reset`.

## Verify

```bash
simulith verify cloudwatch-alarms --skip-aws   # CI smoke (Simulith-only)
simulith verify cloudwatch-alarms              # full parity vs AWS sandbox (P-dev)
```

Scenarios: `put-describe-alarms`, `delete-alarms`, `alarm-evaluation`.

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

## Console

Open **CloudWatch → Alarms** in the local Console ([console.md](console.md)) — read-only **DescribeAlarms** list and detail.

## Related

See also [cloudwatch-metrics.md](cloudwatch-metrics.md) · [cloudwatch.md](cloudwatch.md) (Logs).
