# Parity release history

Time series of **API ops available** and **verify coverage** from [aws-parity-overview.md](aws-parity-overview.md), captured at each product release.

> Snapshots are recorded automatically at each product release.

Last updated: 2026-07-29.

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
| v0.38.0 | 2026-07-23 | 77 | 48/48 | 9/9 | 7 |
| v0.39.0 | 2026-07-23 | 77 | 48/48 | 9/9 | 7 |
| v0.40.0 | 2026-07-23 | 77 | 48/48 | 9/9 | 7 |
| v0.41.0 | 2026-07-24 | 77 | 48/48 | 9/9 | 7 |
| v0.42.0 | 2026-07-24 | 77 | 48/48 | 9/9 | 7 |
| v0.43.0 | 2026-07-24 | 77 | 48/48 | 9/9 | 7 |
| v0.44.0 | 2026-07-24 | 77 | 48/48 | 9/9 | 7 |
| v0.46.0 | 2026-07-25 | 77 | 48/48 | 9/9 | 7 |
| v0.47.0 | 2026-07-25 | 77 | 48/48 | 9/9 | 7 |
| v0.48.0 | 2026-07-27 | 77 | 48/48 | 9/9 | 7 |
| v0.49.0 | 2026-07-27 | 77 | 48/48 | 9/9 | 7 |
| v0.50.0 | 2026-07-27 | 77 | 48/48 | 9/9 | 7 |
| v0.51.0 | 2026-07-27 | 77 | 48/48 | 9/9 | 7 |
| v0.52.0 | 2026-07-27 | 77 | 48/48 | 9/9 | 7 |
| v0.53.0 | 2026-07-28 | 77 | 48/48 | 9/9 | 7 |
| v0.54.0 | 2026-07-28 | 77 | 48/48 | 9/9 | 7 |
| v0.55.0 | 2026-07-28 | 93 | 48/48 | 9/9 | 8 |
| v0.56.0 | 2026-07-29 | 93 | 48/48 | 9/9 | 8 |
| v0.57.0 | 2026-07-29 | 93 | 48/48 | 9/9 | 9 |
| v0.58.0 | 2026-07-29 | 102 | 48/48 | 9/9 | 10 |
| v0.59.0 | 2026-07-29 | 102 | 48/48 | 9/9 | 10 |
| v0.60.0 | 2026-07-29 | 102 | 48/48 | 9/9 | 10 |
| v0.61.0 | 2026-07-29 | 102 | 48/48 | 9/9 | 10 |

## Notes

- **Total ops** — shipped HTTP operations across all services (see executive summary in parity overview).
- **Foundation verify** — DynamoDB + SQS + SSM + S3 ops with `simulith verify` coverage where applicable.
- **Lambda verify** — curated scenario count (not 1:1 with API ops).
- Snapshots are appended automatically during product release when parity overview changes.

## Related

- [aws-parity-overview.md](aws-parity-overview.md)
- [compatibility-matrix.md](compatibility-matrix.md)
- [compatibility.md](compatibility.md)
