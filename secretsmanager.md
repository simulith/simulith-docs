# Secrets Manager — Simulith

Local AWS Secrets Manager emulation for development and testing.

## Overview

Simulith emulates the Secrets Manager **JSON 1.1** API on the same port as other services (default `:4566`).

- **SigV4 service name:** `secretsmanager`
- **Content-Type:** `application/x-amz-json-1.1`
- **Header:** `X-Amz-Target: SecretsManager.<Operation>`

Compatible with AWS CLI (`aws secretsmanager`) and AWS SDKs when using `--endpoint-url http://localhost:4566`.

## Implemented operations

| Operation | X-Amz-Target | Status |
| --- | --- | --- |
| CreateSecret | `SecretsManager.CreateSecret` | ✓ |
| GetSecretValue | `SecretsManager.GetSecretValue` | ✓ |
| ListSecrets | `SecretsManager.ListSecrets` | ✓ |
| DeleteSecret | `SecretsManager.DeleteSecret` | ✓ (immediate local delete) |

## Limits (MVP)

- Plain `SecretString` only (no binary secrets, KMS keys, or rotation)
- No recovery window — `ForceDeleteWithoutRecovery` deletes immediately
- `ListSecrets` pagination stub (returns full list)
- Distinct from SSM SecureString — use this API for Terraform `aws_secretsmanager_secret`

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws secretsmanager create-secret \
  --endpoint-url "$EP" \
  --name demo-secret \
  --secret-string 'my-local-value'

aws secretsmanager get-secret-value \
  --endpoint-url "$EP" \
  --secret-id demo-secret

aws secretsmanager list-secrets --endpoint-url "$EP"

aws secretsmanager delete-secret \
  --endpoint-url "$EP" \
  --secret-id demo-secret \
  --force-delete-without-recovery
```

## Verify

```bash
simulith verify secretsmanager --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify secretsmanager                     # AWS parity (requires AWS credentials)
simulith verify secretsmanager --filter secret-crud  # subset by scenario name prefix
```

Scenarios: `secret-crud-lifecycle`, `get-secret-value`. See [compatibility.md](compatibility.md).

## Related

- Backlog:
- SSM Parameter Store (different API): [`ssm.md`](ssm.md)
