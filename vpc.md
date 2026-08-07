# VPC (EC2 networking) — Simulith

Local Amazon VPC networking emulation via the **EC2 Query API**.  / .

## Overview

Simulith emulates **VPC, subnet, security group, IGW, route table, and gateway endpoint** resources on the same port as other services (default `:4566`).

- **SigV4 service name:** `ec2`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2016-11-15`
- **Persistence:** SQLite (`ec2_*` tables)

Compatible with AWS CLI (`aws ec2`) and Terraform `aws_vpc` / `aws_subnet` / `aws_security_group` when using provider endpoint override.

## Implemented operations

| Area | Operations |
| --- | --- |
| VPC | CreateVpc, DeleteVpc, DescribeVpcs, ModifyVpcAttribute, DescribeVpcAttribute |
| Subnet | CreateSubnet, DeleteSubnet, DescribeSubnets |
| Security group | CreateSecurityGroup, DeleteSecurityGroup, DescribeSecurityGroups, Authorize/Revoke SecurityGroupIngress/Egress |
| Internet gateway | CreateInternetGateway, Attach/DetachInternetGateway, DescribeInternetGateways, DeleteInternetGateway |
| Routing | CreateRouteTable, DeleteRouteTable, DescribeRouteTables, CreateRoute, DeleteRoute, Associate/DisassociateRouteTable |
| VPC endpoints | CreateVpcEndpoint, DescribeVpcEndpoints, ModifyVpcEndpoint, DeleteVpcEndpoints |
| Tags | CreateTags, DescribeTags |

## Terraform

Green-path example: [`examples/terraform/vpc/network-min/`](examples/terraform/vpc/network-min/) — `terraform apply` + **`terraform destroy`**.

```hcl
provider "aws" {
  endpoints { ec2 = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
  # ...
}
```

## Limits

- Metadata / logical routing only — no real ENI or network namespace isolation
- Interface VPC endpoints (Secrets Manager) deferred

## Verify

```bash
simulith verify vpc --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify vpc                     # AWS parity (DescribeVpcs after CreateVpc)
simulith verify vpc --filter vpc-subnet # subset by scenario name prefix
```

Scenarios: `vpc-subnet-sg-lifecycle`, `lambda-vpc-proxy-reachability`. Lambda invoke scenario skips when `node` is not on PATH.

## Console

Panel **`/vpc`**: list VPCs, subnets, and security group ingress/egress rules via Describe* APIs. See [console.md](console.md).

## Seed

Default fixture includes **`demo-vpc`** (`10.0.0.0/16`), **`demo-database-subnet`** (`10.0.1.0/24`), and **`demo-postgres-sg`** — applied on `simulith seed` before RDS. See [seed.md](seed.md).

## Related

- RDS + Lambda VPC: [`lambda.md`](lambda.md), [`rds.md`](rds.md)
