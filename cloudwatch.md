# CloudWatch Logs — Simulith

Local AWS CloudWatch **Logs** emulation for development and testing (initial slice — not Metrics, Alarms, or Insights).

## Overview

Simulith emulates the CloudWatch Logs **JSON 1.1** API on the same port as other services (default `:4566`).

- **SigV4 service name:** `logs`
- **Content-Type:** `application/x-amz-json-1.1`
- **Header:** `X-Amz-Target: Logs_20140328.<Operation>`

Compatible with AWS CLI (`aws logs`) and AWS SDKs when using `--endpoint-url http://localhost:4566`.

## What you can do

| Operation | X-Amz-Target | Status |
| --- | --- | --- |
| CreateLogGroup | `Logs_20140328.CreateLogGroup` | ✓ |
| DeleteLogGroup | `Logs_20140328.DeleteLogGroup` | ✓ |
| DescribeLogGroups | `Logs_20140328.DescribeLogGroups` | ✓ |
| CreateLogStream | `Logs_20140328.CreateLogStream` | ✓ |
| DescribeLogStreams | `Logs_20140328.DescribeLogStreams` | ✓ |
| PutLogEvents | `Logs_20140328.PutLogEvents` | ✓ |

CloudFormation `AWS::Logs::LogGroup` provisions a real log group when the Logs API is available.

## What Simulith does not do

| Area | Notes |
| --- | --- |
| `GetLogEvents`, `FilterLogEvents`, Insights | Read path deferred |
| CloudWatch Metrics, Alarms, Dashboards | Separate backlog |
| Subscription filters, metric filters | Not emulated |
| Cross-account / cross-region | Single local account/region |

## Persistence

Log groups, streams, and events are stored in SQLite (`cloudwatch_log_*` tables). `simulith reset` clears them.

## Verify

```bash
simulith verify cloudwatch --skip-aws   # CI smoke (Simulith-only)
simulith verify cloudwatch              # full parity vs AWS sandbox (P-dev)
```

Scenarios: `log-group-lifecycle`, `put-log-events`. See [compatibility.md](compatibility.md).

## Terraform

Green path: [`examples/terraform/cloudwatch/`](examples/terraform/cloudwatch/) — `aws_cloudwatch_log_group` apply + destroy with `endpoints { logs }`. See [terraform-integration.md](terraform-integration.md).

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws logs create-log-group --log-group-name /aws/lambda/demo --endpoint-url "$EP"
aws logs create-log-stream --log-group-name /aws/lambda/demo --log-stream-name stream1 --endpoint-url "$EP"
aws logs put-log-events --log-group-name /aws/lambda/demo --log-stream-name stream1 \
  --log-events timestamp=1726339200000,message=hello --endpoint-url "$EP"
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/ --endpoint-url "$EP"
```
