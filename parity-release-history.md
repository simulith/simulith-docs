# Parity release history

Time series of **API ops available** and **verify coverage** from [aws-parity-overview.md](aws-parity-overview.md), captured at each product release.

> Snapshots are recorded automatically at each product release.

Last updated: 2026-07-23.

## Summary table

| Release | Recorded | Total ops | Foundation verify | Lambda verify | Services |
| --- | --- | ---: | --- | --- | ---: |
| v0.30.0 | 2026-07-21 | 73 | 48/48 | 9/9 | 6 |
| v0.31.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.32.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.33.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.34.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.35.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.36.0 | 2026-07-22 | 77 | 48/48 | 9/9 | 7 |
| v0.37.0 | 2026-07-23 | 77 | 48/48 | 9/9 | 7 |

## Notes

- **Total ops** — shipped HTTP operations across all services (see executive summary in parity overview).
- **Foundation verify** — DynamoDB + SQS + SSM + S3 ops with `simulith verify` coverage where applicable.
- **Lambda verify** — curated scenario count (not 1:1 with API ops).
- Snapshots are appended automatically during product release when parity overview changes.

## Related

- [aws-parity-overview.md](aws-parity-overview.md)
- [compatibility-matrix.md](compatibility-matrix.md)
- [compatibility.md](compatibility.md)
