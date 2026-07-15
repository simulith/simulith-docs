# Terraform examples — DynamoDB

| Module | Apply on Simulith | Description |
| --- | --- | --- |
| [`music/`](music/) | Yes | Minimal hash-key table (`Music-tf`); `terraform destroy` supported |
| [`user-table/`](user-table/) | Yes | Cognito user table — PK + 2 GSIs; Terraform apply + `user.json` seed — see [user-table/README.md](user-table/README.md) |

Parity gaps: [aws-parity-overview.md](../../../aws-parity-overview.md)

Parent index: [../README.md](../../../README.md)
