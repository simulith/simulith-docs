# KMS (Key Management Service)

Simulith implements a **minimal CMK slice** for Secrets Manager Terraform integration.

## Protocol

- **Endpoint:** same as runtime (`http://127.0.0.1:4566` by default)
- **Content-Type:** `application/x-amz-json-1.1`
- **X-Amz-Target:** `TrentService.<Operation>`
- **SigV4 signing name:** `kms`

## Implemented operations

| Operation | Notes |
| --- | --- |
| `CreateKey` | Symmetric CMK (`SYMMETRIC_DEFAULT`, `ENCRYPT_DECRYPT`) |
| `DescribeKey` | By key ID, ARN, or `alias/...` |
| `GetKeyPolicy` | Default no-op policy for Terraform read-after-create |
| `GetKeyRotationStatus` | Returns `KeyRotationEnabled: false` |
| `ListResourceTags` | Empty tag list |
| `CreateAlias` | `alias/<name>` → target key |
| `ListAliases` | Optional filter by `KeyId` |
| `Encrypt` | Base64 plaintext in → `CiphertextBlob` (mock envelope) |
| `Decrypt` | Base64 ciphertext in → base64 plaintext |
| `DeleteAlias` | Remove alias before key deletion |
| `ScheduleKeyDeletion` | Delete CMK after aliases removed |

## Behaviour notes

- **No CloudHSM / multi-Region / grants / rotation** — metadata and mock crypto only.
- **Encrypt/Decrypt** use a Simulith-local envelope (`simulith-kms:v1:<keyId>:...`); suitable for local dev and Terraform apply, not AWS-identical ciphertext.
- **Secrets Manager** accepts `KmsKeyId` on `CreateSecret` when the key exists; `DescribeSecret` returns `KmsKeyId`.

## Terraform

Green path: [`examples/terraform/kms/cmk-min/`](examples/terraform/kms/cmk-min/) — `terraform apply` and `terraform destroy` with `-parallelism=1`.

## Backlog

See .

## Seed

Default fixture includes CMK alias **`alias/demo-key`**. See [seed.md](seed.md).

## Console

Panel **`/kms`**: list aliases, describe key, create CMK + optional alias, encrypt/decrypt round-trip. See [console.md](console.md).

## Verify

```bash
simulith verify kms --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify kms                     # AWS parity (CreateKey/DescribeKey metadata)
simulith verify kms --filter cmk-alias  # subset by scenario name prefix
```

Scenarios: `cmk-alias-lifecycle` (CreateKey, DescribeKey by alias, CreateAlias, ListAliases), `encrypt-decrypt-roundtrip` (Encrypt/Decrypt round-trip per side; ciphertext is not cross-compared).
