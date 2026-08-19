# VPC (EC2 networking) — Simulith

Local Amazon VPC networking emulation via the **EC2 Query API**.  / .

## Overview

Simulith emulates **VPC, subnet, security group, IGW, route table, NAT Gateway, EIP, gateway endpoint, and interface endpoint** resources on the same port as other services (default `:4566`).

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
| Elastic IP | AllocateAddress, DescribeAddresses, DisassociateAddress, ReleaseAddress |
| NAT Gateway | CreateNatGateway, DescribeNatGateways, DeleteNatGateway |
| Routing | CreateRouteTable, DeleteRouteTable, DescribeRouteTables, CreateRoute (GatewayId or NatGatewayId), DeleteRoute, Associate/DisassociateRouteTable |
| VPC endpoints | CreateVpcEndpoint, DescribeVpcEndpoints, ModifyVpcEndpoint, DeleteVpcEndpoints (Gateway + Interface metadata) |
| Tags | CreateTags, DescribeTags |
| Network interfaces | DescribeNetworkInterfaces (stub ENIs for Interface endpoints and NAT Gateways; empty otherwise) |

## Terraform

Green-path examples:

- [`examples/terraform/vpc/network-min/`](examples/terraform/vpc/network-min/) — gateway endpoints
- [`examples/terraform/vpc/interface-endpoint-min/`](examples/terraform/vpc/interface-endpoint-min/) — Interface Secrets Manager endpoint
- [`examples/terraform/vpc/nat-gateway-min/`](examples/terraform/vpc/nat-gateway-min/) — EIP + NAT Gateway + private default route

```hcl
provider "aws" {
  endpoints { ec2 = "http://127.0.0.1:4566" }
  skip_credentials_validation = true
  # ...
}
```

## Limits

- Metadata / logical routing only — no real ENI or network namespace isolation
- `DescribeNetworkInterfaces` returns stub ENIs for Interface VPC endpoints and NAT Gateways (empty otherwise) so Terraform can read NAT `network_interface_id` / endpoint `subnet_configuration`. Security group destroy still works after those resources are deleted.
- `DescribeVpcAttribute` `enableNetworkAddressUsageMetrics` is a **false stub**
- Interface VPC endpoints are **metadata only** (subnet/SG/private DNS + stub DNS/ENI IDs). Packets do not traverse PrivateLink; clients still use the Simulith HTTP endpoint.
- NAT Gateway and Elastic IPs are **metadata only** (stub ENI + documentation-range public IP). Packets are not NAT'd or forwarded via IGW; clients still use the Simulith HTTP endpoint.

## Verify

```bash
simulith verify vpc --skip-aws          # Simulith-only smoke (4 scenarios)
simulith verify vpc                     # AWS parity (DescribeVpcs after CreateVpc)
simulith verify vpc --filter vpc-subnet # subset by scenario name prefix
```

Scenarios: `vpc-subnet-sg-lifecycle`, `lambda-vpc-proxy-reachability`, `interface-vpc-endpoint-lifecycle`, `nat-gateway-lifecycle`. Lambda invoke scenario skips when `node` is not on PATH.

## Console

Panel **`/vpc`**: list VPCs, subnets, and security group ingress/egress rules via Describe* APIs. See [console.md](console.md).

## Seed

Default fixture includes **`demo-vpc`** (`10.0.0.0/16`), **`demo-database-subnet`** (`10.0.1.0/24`), and **`demo-postgres-sg`** — applied on `simulith seed` before RDS. See [seed.md](seed.md).

## Related

- RDS + Lambda VPC: [`lambda.md`](lambda.md), [`rds.md`](rds.md)
