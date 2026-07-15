# SSM Parameter Store — Simulith runtime

Local **AWS Systems Manager Parameter Store** emulation for the MVP subset (Put/Get/Delete single parameter, bulk read by names and path).

## Protocol

SSM uses **AWS JSON 1.1** (`application/x-amz-json-1.1` + `X-Amz-Target: AmazonSSM.<Operation>`). Simulith multiplexes `POST /` with DynamoDB (JSON 1.0) and SQS (Query) on the same listener.

## Implemented operations

| Operation | Status | Notes |
| --- | --- | --- |
| PutParameter | **Available** | Create or overwrite; SQLite persistence |
| GetParameter | **Available** | Returns `Parameter` with ARN, version, last modified |
| DeleteParameter | **Available** | Removes one parameter by name |
| DeleteParameters | **Available** | Up to 10 names; missing/invalid → `InvalidParameters` |
| GetParameters | **Available** | Up to 10 names; `Parameters` sorted A–Z; missing → `InvalidParameters` |
| GetParametersByPath | **Available** | Path prefix filter; `Recursive` default **false** (one level); pagination |
| DescribeParameters | **Available** | MVP: `ParameterFilters` Name Equals/BeginsWith only; for Terraform refresh |
| AddTagsToResource | **Available** | `ResourceType=Parameter`; merge tags by key |
| RemoveTagsFromResource | **Available** | `ResourceType=Parameter` |
| ListTagsForResource | **Available** | Parameter `TagList` sorted by key |

Not implemented yet: full ParameterFilters, labels, real AWS KMS encryption.

## Parameter tags

- **PutParameter** — optional `Tags` merged on create; on overwrite, omitted `Tags` preserves existing tags
- **AddTagsToResource** — `ResourceType=Parameter`, `ResourceId` = parameter name; merges/overwrites keys
- **RemoveTagsFromResource** — removes listed tag keys
- **ListTagsForResource** — returns `TagList` (empty array when none)
- Terraform `tags = { ... }` on `aws_ssm_parameter` uses these APIs — see [`examples/terraform/ssm/`](examples/terraform/ssm/)

## SecureString

- **PutParameter** with `Type=SecureString` stores a **mock-encrypted** value in SQLite (prefix `simulith-secure:v1:` + base64). **Not real KMS** — local dev only.
- **GetParameter** / **GetParameters** / **GetParametersByPath**: without `WithDecryption`, SecureString values return the stored ciphertext; with `WithDecryption=true`, return decrypted plaintext (same as AWS semantics).
- **`KeyId`** on Put is accepted and ignored (no KMS key management).
- Terraform `aws_ssm_parameter` with `type = "SecureString"` works on the green path — see [`examples/terraform/ssm/`](examples/terraform/ssm/).

## PutParameter

Copy-paste CLI: **[aws-cli-examples.md — SSM](aws-cli-examples.md#ssm-parameter-store)**.

Required on create: `Name` (must start with `/`; leading/trailing spaces are trimmed), `Value`, `Type` (`String`, `StringList`, or `SecureString`).

`Overwrite` defaults to `false`. If the parameter exists and `Overwrite` is false, Simulith returns **ParameterAlreadyExists**.

On overwrite, `Type` may be omitted to keep the existing type.

## GetParameter

Request: `Name` (full parameter path). Leading/trailing spaces on the name are trimmed before lookup (same as PutParameter).

`WithDecryption` controls SecureString responses (see SecureString section). For `String` / `StringList`, decryption is a no-op.

Response includes `Parameter` with `Name`, `Type`, `Value`, `Version`, `LastModifiedDate` (Unix seconds), and `ARN` (local account `000000000000` by default).

## DeleteParameter

Request: `Name` (full parameter path). Same name validation as Put/Get.

Response: empty JSON object `{}` with HTTP 200 when the parameter existed and was removed.

If the name does not exist, Simulith returns **ParameterNotFound** (same shape as GetParameter).

AWS documents a 30-second wait before re-creating a parameter with the same name after delete; Simulith does not enforce that cooldown locally.

## DeleteParameters

Request: `Names` (required, 1–10 full parameter paths). Each name is trimmed.

Response: HTTP 200 with `DeletedParameters` (names removed) and `InvalidParameters` (invalid format or not found). Unlike **DeleteParameter**, a missing name is listed in `InvalidParameters`, not a fault on the whole request.

Empty `Names` or more than 10 names → **ValidationException**.

## GetParameters

Request: `Names` (required, 1–10 full parameter paths). Each name is trimmed; invalid or missing names appear in `InvalidParameters` (not an error).

Response: `Parameters` sorted alphabetically by name; `InvalidParameters` is always present (empty array when none).

`WithDecryption` controls SecureString responses (see SecureString section).

## GetParametersByPath

Request: `Path` (required, leading `/`; trailing `/` on the path is trimmed). Optional:

- `Recursive` — default **false**: only parameters one segment below the path (e.g. `/app/demo/api-url` under `/app/demo`, not `/app/demo/nested/x`). **true**: all descendants under the prefix.
- `MaxResults` — 1–10 per page (default 10 when omitted or out of range).
- `NextToken` — opaque offset token from a previous page; invalid token → **InvalidNextToken**.

Response: `Parameters` for the current page (sorted by name). `NextToken` when more results exist.

`WithDecryption` controls SecureString responses (see SecureString section).

`ParameterFilters` are not supported in MVP.

## Persistence

Parameters are stored in SQLite (`ssm_parameters`). See [persistence.md](persistence.md).

`simulith reset` clears SSM rows with DynamoDB and SQS.

Optional snapshot v1 `"ssm"` block is supported.

## Deviations (MVP)

| Area | Simulith MVP |
| --- | --- |
| SecureString | Mock local encryption at rest; `WithDecryption` returns plaintext; no AWS KMS |
| Parameter history | Latest version only in API |
| Tags | Accepted on Put (merged); **AddTagsToResource** / **RemoveTagsFromResource** / **ListTagsForResource** for parameters |
| Tier / policies | **Tier** returned as `Standard` on Get/Describe (MVP stub for Terraform); tier input on Put ignored |
| Post-delete name reuse delay | Not enforced (AWS: ~30s) |
| DescribeParameters / ParameterFilters | **MVP subset** — Name Equals/BeginsWith only; other filter keys ignored |
| DeleteParameters (batch) | **Available** — up to 10 names per call |
| GetParametersByPath at scale | Full-table name scan in memory (local MVP) |
| NextToken format | Simulith offset token (not AWS-compatible) |

---

## Related

- [compatibility-matrix.md](compatibility-matrix.md) — public MVP operation × verify coverage matrix
- [compatibility.md](compatibility.md) — `simulith verify ssm` parity checks
- [aws-cli-examples.md](aws-cli-examples.md)
- [persistence.md](persistence.md)
