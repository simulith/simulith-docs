# Cognito Identity Provider — Simulith

Local Amazon Cognito User Pools emulation for development and testing.

## Overview

Simulith emulates **cognito-idp** JSON 1.1 on the same port as other services (default `:4566`).

- **SigV4 service name:** `cognito-idp`
- **Content-Type:** `application/x-amz-json-1.1`
- **Header:** `X-Amz-Target: AWSCognitoIdentityProviderService.<Operation>`
- **JWKS (no SigV4):** `GET /{userPoolId}/.well-known/jwks.json`

Compatible with AWS CLI (`aws cognito-idp`) and SDKs when using `--endpoint-url http://localhost:4566`.

## Implemented operations

| Operation | Status |
| --- | --- |
| CreateUserPool / DescribeUserPool / ListUserPools / DeleteUserPool / UpdateUserPool | ✓ |
| CreateUserPoolClient / DescribeUserPoolClient / ListUserPoolClients / DeleteUserPoolClient | ✓ |
| CreateGroup / GetGroup / ListGroups / DeleteGroup | ✓ |
| CreateUserPoolDomain / DescribeUserPoolDomain / DeleteUserPoolDomain | ✓ (metadata) |
| JWKS endpoint | ✓ RSA key per pool |
| AdminCreateUser / AdminGetUser | ✓ |
| AdminSetUserPassword / AdminConfirmSignUp | ✓ |
| AdminEnableUser / AdminDisableUser | ✓ |
| AdminInitiateAuth (`ADMIN_USER_PASSWORD_AUTH`) | ✓ RS256 Access + Id tokens |
| Lambda triggers (`PreSignUp`, `PostConfirmation`) | ✓ on admin lifecycle |

## Limits

- Passwords stored plaintext locally (dev only)
- Refresh token is an opaque stub (no refresh rotation)
- No Hosted UI / OAuth authorize / token endpoints yet
- No MFA TOTP complete flows
- No Identity Pools
- No `SignUp` / `ConfirmSignUp` public APIs yet (admin path + triggers supported)
- Domain is metadata only (no real CloudFront)
- `UpdateUserPool` merges JSON config; not full AWS parity

## Lambda triggers

Configure on the user pool (`CreateUserPool` / `UpdateUserPool`):

```json
"LambdaConfig": {
  "PreSignUp": "my-pre-sign-up",
  "PostConfirmation": "my-post-confirmation"
}
```

Function names or Lambda ARNs are accepted. Simulith invokes synchronously via the local Lambda service.

| Trigger | Invoked from | triggerSource |
| --- | --- | --- |
| PreSignUp | `AdminCreateUser` (before persist) | `PreSignUp_AdminCreateUser` |
| PostConfirmation | `AdminConfirmSignUp`, permanent `AdminSetUserPassword`, or auto-confirm from PreSignUp | `PostConfirmation_ConfirmSignUp` |

PreSignUp Lambda returns the event with optional `response.autoConfirmUser`, `autoVerifyEmail`, `autoVerifyPhone`. Lambda errors return `UserLambdaValidationException`.

Example (function must exist in Simulith Lambda):

```bash
aws cognito-idp create-user-pool \
  --endpoint-url "$EP" \
  --pool-name triggers-demo \
  --lambda-config PreSignUp=my-pre-sign-up,PostConfirmation=my-post-confirmation
```

## Verify

```bash
simulith verify cognito --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify cognito                     # AWS parity (requires AWS credentials)
simulith verify cognito --filter admin-auth  # subset by scenario name prefix
```

Scenarios: `user-pool-client-lifecycle`, `admin-auth-jwks`.

## Console

Panel **Cognito** (`/cognito`) — list user pools, inspect app clients and groups, open JWKS URL. .

Default **Seed** includes User Pool **`demo-pool`** (`us-east-1_demopool1`), app client **`demo-client`**, and group **`admin`**. .

Inspect-only create/delete in Console (CLI / Terraform for custom pools).

## Terraform

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

POOL=$(aws cognito-idp create-user-pool \
  --endpoint-url "$EP" \
  --pool-name demo-local \
  --query 'UserPool.Id' --output text)

CLIENT=$(aws cognito-idp create-user-pool-client \
  --endpoint-url "$EP" \
  --user-pool-id "$POOL" \
  --client-name app \
  --query 'UserPoolClient.ClientId' --output text)

aws cognito-idp admin-create-user \
  --endpoint-url "$EP" \
  --user-pool-id "$POOL" \
  --username alice \
  --user-attributes Name=email,Value=alice@example.com \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --endpoint-url "$EP" \
  --user-pool-id "$POOL" \
  --username alice \
  --password 'Secret123!' \
  --permanent

aws cognito-idp admin-initiate-auth \
  --endpoint-url "$EP" \
  --user-pool-id "$POOL" \
  --client-id "$CLIENT" \
  --auth-flow ADMIN_USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=alice,PASSWORD=Secret123!

curl -s "$EP/$POOL/.well-known/jwks.json"
```

## Terraform

Green path: [`examples/terraform/cognito/`](examples/terraform/cognito/).

```hcl
endpoints {
  cognito_idp = var.simulith_endpoint
}
```

## Related

- Backlog:
