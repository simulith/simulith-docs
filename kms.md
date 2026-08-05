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
| `CreateAlias` | `alias/<name>` → target key |
| `ListAliases` | Optional filter by `KeyId` |
| `Encrypt` | Base64 plaintext in → `CiphertextBlob` (mock envelope) |
| `Decrypt` | Base64 ciphertext in → base64 plaintext |

## Behaviour notes

- **No CloudHSM / multi-Region / grants / rotation** — metadata and mock crypto only.
- **Encrypt/Decrypt** use a Simulith-local envelope (`simulith-kms:v1:<keyId>:...`); suitable for local dev and Terraform apply, not AWS-identical ciphertext.
- **Secrets Manager** accepts `KmsKeyId` on `CreateSecret` when the key exists; `DescribeSecret` returns `KmsKeyId`.

## Terraform

Green path: [`examples/terraform/kms/cmk-min/`](examples/terraform/kms/cmk-min/).

## Backlog

See .
