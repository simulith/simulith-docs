# IAM — Simulith

Local Amazon IAM emulation via the **IAM Query API** for loyaleasy RDS Proxy roles.  / .

## Overview

- **SigV4 service name:** `iam`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2010-05-08`
- **Persistence:** SQLite (`iam_*` tables)

Compatible with Terraform `aws_iam_role`, `aws_iam_policy`, and `aws_iam_role_policy_attachment` when using provider endpoint override.

## Implemented operations

| Operation | Notes |
| --- | --- |
| CreateRole / GetRole / DeleteRole | Assume-role policy document stored verbatim |
| CreatePolicy / GetPolicy / DeletePolicy | Managed policy JSON document |
| AttachRolePolicy / DetachRolePolicy | Role ↔ policy ARN |
| ListAttachedRolePolicies | For Terraform refresh |

## Terraform

Green-path example (proxydb IAM subset): [`examples/terraform/iam/loyaleasy-min/`](examples/terraform/iam/loyaleasy-min/).

```hcl
provider "aws" {
  endpoints { iam = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
}
```

## Limits

- No policy enforcement against Secrets Manager/KMS at runtime (metadata only)
- No IAM users, groups, or STS AssumeRole simulation
- Console panel deferred

## Follow-on surfaces

Verify, Console, Web messaging, simulith-docs sync — separate stories per expansion template.
