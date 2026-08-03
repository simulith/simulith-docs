# RDS Postgres sidecar — Simulith

Local Amazon RDS emulation via **AWS JSON 1.1** with a **Postgres 15 Docker sidecar** per DB instance.  / .

## Overview

- **SigV4 service name:** `rds`
- **Protocol:** AWS JSON 1.1 (`Content-Type: application/x-amz-json-1.1`, `X-Amz-Target: AmazonRDSv2014-10-31.<Operation>`)
- **Persistence:** SQLite (`rds_db_*` tables)
- **Sidecar:** `postgres:15-alpine` via Docker CLI (one container per instance)

Compatible with Terraform `aws_db_subnet_group`, `aws_db_parameter_group`, and `aws_db_instance` when using provider endpoint override.

## Implemented operations

| Operation | Notes |
| --- | --- |
| CreateDBSubnetGroup | Subnet metadata only (no ENI placement) |
| DescribeDBSubnetGroups | Filter by name optional |
| DeleteDBSubnetGroup | Blocked when referenced by an instance |
| CreateDBParameterGroup | Minimal stub (family + description) |
| DescribeDBParameterGroups | |
| DeleteDBParameterGroup | |
| CreateDBInstance | **Postgres only** — starts Docker sidecar |
| DescribeDBInstances | Returns endpoint `127.0.0.1:<hostPort>` |
| DeleteDBInstance | Stops/removes sidecar container |

## Local connectivity

`CreateDBInstance` maps Postgres to a free host port. `DescribeDBInstances` returns:

- `Endpoint.Address`: `127.0.0.1`
- `Endpoint.Port`: mapped host port (e.g. `15432`)

Connect with `psql -h 127.0.0.1 -p <port> -U <MasterUsername> -d <DBName>`.

**Requires Docker** on PATH for real sidecar lifecycle. Unit tests use a mock sidecar.

## Terraform

Green-path example (loyaleasy-min subset): [`examples/terraform/rds/loyaleasy-min/`](examples/terraform/rds/loyaleasy-min/).

```hcl
provider "aws" {
  endpoints { rds = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
  # ...
}
```

Combine with [`examples/terraform/vpc/loyaleasy-min/`](examples/terraform/vpc/loyaleasy-min/) for VPC + subnet + security group resources.

## Limits

- Postgres engine only in v1
- No RDS Proxy, snapshots, or multi-AZ
- Subnet groups store subnet IDs without validating against EC2 DescribeSubnets
- Parameter group parameters are accepted by Terraform but not applied to the sidecar
