# Terraform examples — DynamoDB

| Module | Apply on Simulith | Description |
| --- | --- | --- |
| [`music/`](music/) | Yes | Minimal hash-key table (`Music-tf`); `terraform destroy` supported |
| [`user-table/`](user-table/) | Yes | Cognito user table — PK + 2 GSIs; Terraform apply + `user.json` seed — see [user-table/README.md](user-table/README.md) |

Future work: cursor/company/future-work/dynamodb/

Parent index: [../README.md](../README.md)
