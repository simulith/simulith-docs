# RDS Postgres sidecar — Simulith

Local Amazon RDS emulation via **AWS JSON 1.1** with a **Postgres 15 Docker sidecar** per DB instance and **RDS Proxy TCP relay**.  / ,  / .

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
| CreateDBProxy | POSTGRESQL proxy metadata |
| DescribeDBProxies | Returns endpoint `127.0.0.1:<proxyPort>` after target registration |
| DeleteDBProxy | Stops TCP relay and deletes proxy |
| RegisterDBProxyTargets | Links proxy to DB instance; starts TCP relay |
| DeregisterDBProxyTargets | Removes target; stops relay when last target gone |
| ModifyDBProxyTargetGroup | Stub (connection pool config ignored locally) |

## Local connectivity

`CreateDBInstance` maps Postgres to a free host port. `DescribeDBInstances` returns:

- `Endpoint.Address`: `127.0.0.1`
- `Endpoint.Port`: mapped host port (e.g. `15432`)

Connect with `psql -h 127.0.0.1 -p <port> -U <MasterUsername> -d <DBName>`.

**RDS Proxy:** after `RegisterDBProxyTargets`, connect to the proxy endpoint (`127.0.0.1:<proxyPort>`) — TCP relay forwards to the instance sidecar. Auth secret ARNs are metadata only in v1 (no live Secrets Manager fetch).

**Requires Docker** on PATH for real sidecar lifecycle. Unit tests use a mock sidecar.

## Terraform

Green-path examples:

- Instance subset: [`examples/terraform/rds/postgres-min/`](examples/terraform/rds/postgres-min/) — `terraform apply` + **`terraform destroy`**; embedded VPC; Docker required
- Proxy subset: [`examples/terraform/rds/proxy-min/`](examples/terraform/rds/proxy-min/) — apply local; formal destroy path pending

```hcl
provider "aws" {
  endpoints { rds = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
  # ...
}
```

Combine with [`examples/terraform/vpc/network-min/`](examples/terraform/vpc/network-min/) for VPC + subnet + security group resources.

## Default seed (`demo-db`)

After `simulith seed` or Console **Seed demo data**, Postgres instance **`demo-db`** is created with sidecar endpoint `127.0.0.1:<port>`, database `demoapp`, user `demoapp`, password `local-dev-password`.  / . **Docker required** on the Simulith runtime host. Fixture format: [seed.md](seed.md).

```bash
psql "postgresql://demoapp:local-dev-password@127.0.0.1:<port>/demoapp"
```

## Console

Read-only panel at **`/rds`** — **DescribeDBInstances** lists Postgres instances with status and sidecar endpoint (`127.0.0.1:<port>`). See [console.md](console.md) and [console-parity-overview.md](console-parity-overview.md).

## Verify

```bash
simulith verify rds --skip-aws          # Simulith-only smoke (2 scenarios; needs Docker)
simulith verify rds                     # AWS parity (parameter group describe in scenario 1)
simulith verify rds --filter db-instance  # subset by scenario name prefix
```

Scenarios: `db-instance-lifecycle`, `db-proxy-tcp-connect`. **Docker must be available on the Simulith runtime host** (where `simulith start` runs), not only on the verify client. Scenarios skip when docker is missing or the sidecar cannot start (e.g. Simulith inside a container without DinD).

## Limits

- Postgres engine only in v1
- No snapshots or multi-AZ
- RDS Proxy: no connection pooling semantics; TLS not terminated locally
- Subnet groups store subnet IDs without validating against EC2 DescribeSubnets
- Parameter group parameters are accepted by Terraform but not applied to the sidecar
