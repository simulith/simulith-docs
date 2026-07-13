# Trust bundle — enterprise evaluation package

Reproducible **zip** for sales and POC evaluators: public compatibility matrix, verify smoke reports (JSON + HTML), and quickstart — FW-PRD-003 / SML-053.

**Sales narrative:** `cursor/company/sales/trust-bundle.md`  
**Editions (draft):** `cursor/company/sales/editions-and-licensing.md`  
**Matrix (FW-CMP-003):** [compatibility-matrix.md](compatibility-matrix.md) · **Public mirror:** [simulith-docs/compatibility-matrix.md](https://github.com/simulith/simulith-docs/blob/main/compatibility-matrix.md)

---

## Quick start

From `runtime/` (port **4566** must be free):

```bash
go build -o bin/simulith ./cmd/simulith
bash ./scripts/build-trust-bundle.sh
```

Output: `dist/simulith-trust-bundle-YYYYMMDD.zip`

---

## What the script does

1. **`ci-verify-smoke.sh`** — seed → start server → `simulith verify dynamodb|sqs|ssm|s3|lambda --skip-aws` → five JSON files
2. **`simulith report --output-html`** — HTML for each JSON
3. **Copy** `docs/compatibility-matrix.md` and `docs/quickstart.md` into the bundle
4. **Write** bundle `README.md` (timestamp, git commit when available)
5. **Zip** staging directory

Same verify commands as GitHub Actions **Parity smoke** — see [compatibility.md § CI](compatibility.md#continuous-integration-github-actions).

---

## Bundle layout

```text
README.md
docs/
  compatibility-matrix.md
  quickstart.md
reports/
  verify-dynamodb.json
  verify-dynamodb.html
  verify-sqs.json
  verify-sqs.html
  verify-ssm.json
  verify-ssm.html
  verify-s3.json
  verify-s3.html
  verify-lambda.json
  verify-lambda.html
```

Reports use schema `version: 1`, **`mode: smoke`** (no `compatibilityPercent`). Lambda invoke scenario is **skipped** when `node` is not on PATH (typical in minimal Docker runtime image); other Lambda scenarios still run.

---

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `SIMULITH_BIN` | `./bin/simulith` | Built binary (or `go run ./cmd/simulith`) |
| `DIST_DIR` | `dist` | Output directory |
| `OUTPUT_ZIP` | `dist/simulith-trust-bundle-YYYYMMDD.zip` | Archive path |
| `STAGING_DIR` | `dist/trust-bundle-staging` | Temp layout before zip |

Verify smoke inherits `ARTIFACTS_DIR` internally (set to `staging/reports`).

Optional extended DynamoDB report (not in default bundle): set `VERIFY_DDB_EXTENDED=true` when calling `ci-verify-smoke.sh` directly; default bundle script does **not** include extended scenarios.

---

## Relationship to CI artifacts

| Source | Contents |
| --- | --- |
| **Parity smoke** CI job | `artifacts/verify-{dynamodb,sqs,ssm,s3,lambda}.json` |
| **Trust bundle** script | Same JSON + HTML reports + matrix + quickstart + README in zip |

Download CI JSON from PR **Checks → Parity smoke → Artifacts**. The Trust bundle is for **offline/email** delivery without GitHub access.

---

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Port 4566 in use | Stop Simulith / Docker compose on 4566 |
| `zip: command not found` | Git Bash on Windows uses PowerShell automatically; on Linux install `zip` or use `python3` |
| Stale matrix in zip | Rebuild after updating `compatibility-matrix.md` |

Generated zips and staging dirs are gitignored (`dist/`).

---

## Deferred (v1)

- PDF generation in script — use browser Print → PDF from HTML reports
- `simulith trust-bundle` CLI subcommand — script only for now
- Auto-download from GitHub Actions — run script locally or from CI checkout

---

## Related

- [compatibility.md](compatibility.md) — verify modes and CI
- [compatibility-matrix.md](compatibility-matrix.md) — FW-CMP-003
- [quickstart.md](quickstart.md) — onboarding
- [terraform-integration.md#green-path-iac](terraform-integration.md#green-path-iac) — IaC evaluation path
- [console.md](console.md) — optional GUI
