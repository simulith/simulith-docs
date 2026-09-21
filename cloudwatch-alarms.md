# CloudWatch Alarms — Simulith

Local **CloudWatch metric alarms** emulation with **metric-based evaluation** and **SNS alarm actions**.

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
| `DescribeAlarms` | List alarms; optional `AlarmNames` filter; returns persisted state |
| `DeleteAlarms` | Delete alarms by name |
| `SetAlarmState` | Manually set alarm state (`OK` / `ALARM` / `INSUFFICIENT_DATA`); triggers SNS actions on transition |

## Evaluation

When **`PutMetricData`** publishes datapoints for a metric referenced by an alarm, Simulith evaluates the alarm using **`GetMetricStatistics`** over the configured `Period` × `EvaluationPeriods` window. Matching alarms transition to:

| State | When |
| --- | --- |
| `ALARM` | All evaluation periods breach the threshold |
| `OK` | All periods have data and at least one period is not breaching |
| `INSUFFICIENT_DATA` | Not enough datapoints in the window (including after create) |

Evaluation runs on **`PutMetricData`** / **`PutMetricAlarm`** (metric publish paths). **`DescribeAlarms`** returns the persisted state (including after **`SetAlarmState`**).

Supported comparison operators: `GreaterThanThreshold`, `GreaterThanOrEqualToThreshold`, `LessThanThreshold`, `LessThanOrEqualToThreshold`. Statistics: `Average`, `Sum`, `Minimum`, `Maximum`, `SampleCount`.

### Eval depth

- **`DatapointsToAlarm`** — M-of-N breaching (defaults to `EvaluationPeriods`; must be ≤ `EvaluationPeriods`).
- **`TreatMissingData`** — `missing` (default), `breaching`, `notBreaching`, `ignore` applied to empty period buckets in the evaluation window.
- Evaluation walks **consecutive** period buckets (not only periods that received datapoints).

## SNS actions

When an alarm **transitions state** and **`ActionsEnabled`** is true, Simulith publishes a CloudWatch-style JSON notification to configured **SNS topic ARNs**:

| New state | Action list used |
| --- | --- |
| `ALARM` | `AlarmActions` |
| `OK` | `OKActions` |
| `INSUFFICIENT_DATA` | `InsufficientDataActions` |

Topics must exist locally (`aws sns create-topic` or Terraform `aws_sns_topic`). Messages are stored in SQLite for inspection; no email/SMS/Lambda fan-out yet.

## What Simulith does not do

| Area | Notes |
| --- | --- |
| Non-SNS action targets | Lambda, SQS, auto-scaling ARNs stored but not invoked |
| Composite alarms, anomaly detectors |  remainder |
| Dashboards |  |

## Persistence

Alarm definitions are stored in SQLite (`cloudwatch_alarms`). Cleared on `simulith reset`.

## Verify

```bash
simulith verify cloudwatch-alarms --skip-aws   # CI smoke (Simulith-only)
simulith verify cloudwatch-alarms              # full parity vs AWS sandbox (P-dev)
```

Scenarios: `put-describe-alarms`, `delete-alarms`, `alarm-evaluation`, `alarm-eval-depth`.

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
