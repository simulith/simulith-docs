# IAM — Simulith

Local Amazon IAM emulation via the **IAM Query API** for RDS Proxy roles.

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

Green-path example (RDS Proxy IAM subset): [`examples/terraform/iam/proxy-roles-min/`](examples/terraform/iam/proxy-roles-min/).

```hcl
provider "aws" {
  endpoints { iam = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
}
```

## Limits

- No policy enforcement against Secrets Manager/KMS at runtime (metadata only)
- No IAM users, groups, or STS AssumeRole simulation
- No **ListRoles** API — Console loads roles by name

## Console

Panel **`/iam`**: load role by name, inspect trust policy and attached managed policies, create RDS Proxy role bundle. See [console.md](console.md).

## Verify

```bash
simulith verify iam --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify iam                     # AWS parity (GetRole / GetPolicy after create)
simulith verify iam --filter rds-proxy  # subset by scenario name prefix
```

Scenarios: `rds-proxy-role-lifecycle`, `managed-policy-get`.

## Follow-on surfaces

Verify, Console, Web messaging, simulith-docs sync — separate stories per expansion template.
