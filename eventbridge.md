# EventBridge — Simulith

Local Amazon EventBridge / CloudWatch Events **schedule rules** that invoke Lambda. .

## Overview

Simulith emulates EventBridge schedule APIs on the same port as other services (default `:4566`).

- **SigV4 service name:** `events`
- **Protocol:** AWS JSON 1.1 (`X-Amz-Target: AWSEvents.<Operation>`)
- **Bus:** default bus only
- **Delivery:** schedule poller invokes Lambda targets via `InvokeSync` (no real EventBridge bus)

Compatible with AWS CLI (`aws events`) and SDKs when using `--endpoint-url http://localhost:4566`.

## Implemented operations

| Operation | Status |
| --- | --- |
| PutRule / DeleteRule / DescribeRule / ListRules | ✓ (schedule expressions) |
| EnableRule / DisableRule | ✓ |
| PutTargets / RemoveTargets / ListTargetsByRule | ✓ (Lambda ARNs) |
| Schedule poller → Lambda Invoke | ✓ `rate(...)`; `cron(...)` ≈ every minute |

## Limits

- No custom event buses / PutEvents
- Cron is a local approximation (≈1 minute), not full AWS cron semantics
- Non-Lambda targets are skipped
- `simulith verify eventbridge` planned

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws events put-rule --endpoint-url "$EP" \
  --name tick --schedule-expression "rate(1 minute)"

aws events put-targets --endpoint-url "$EP" \
  --rule tick \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:000000000000:function:demo"
```

Scheduled event payload shape: `source=aws.events`, `detail-type=Scheduled Event`.

## Terraform

Green path: [`examples/terraform/eventbridge/`](examples/terraform/eventbridge/) — Lambda + `aws_cloudwatch_event_rule` + target.

```hcl
endpoints {
  events = var.simulith_endpoint
  lambda = var.simulith_endpoint
}
```

## Related

- Backlog:
- Study:
