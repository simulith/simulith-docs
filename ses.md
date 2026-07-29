# SES — Simulith

Local Amazon Simple Email Service (Classic) emulation with **outbox capture** (no SMTP). .

## Overview

Simulith emulates **SES Classic** AWS Query on the same port as other services (default `:4566`).

- **SigV4 service name:** `ses`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2010-12-01`
- **Delivery:** messages are stored in a local outbox (inspect via store / future Console panel)

Compatible with AWS CLI (`aws ses`) and SDKs when using `--endpoint-url http://localhost:4566`.

## Implemented operations

| Operation | Status |
| --- | --- |
| VerifyEmailIdentity / DeleteIdentity / ListIdentities | ✓ (auto-verified) |
| GetIdentityVerificationAttributes | ✓ |
| CreateTemplate / GetTemplate / UpdateTemplate / DeleteTemplate / ListTemplates | ✓ |
| SendEmail / SendTemplatedEmail / SendRawEmail | ✓ → outbox |

## Limits

- No real SMTP / internet delivery
- Domain identity / DKIM not implemented
- Configuration sets, bounce/complaint simulation deferred
## Verify

```bash
simulith verify ses --skip-aws          # Simulith-only smoke (2 scenarios)
simulith verify ses                     # AWS parity (identity/template; send is Simulith smoke)
simulith verify ses --filter identity   # subset by scenario name prefix
```

Scenarios: `identity-template-lifecycle`, `send-templated-email`.

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws ses verify-email-identity --endpoint-url "$EP" --email-address otp@example.com

aws ses create-template --endpoint-url "$EP" --cli-input-json '{
  "Template": {
    "TemplateName": "otp",
    "SubjectPart": "Your code {{code}}",
    "TextPart": "Code: {{code}}",
    "HtmlPart": "<p>{{code}}</p>"
  }
}'

aws ses send-templated-email --endpoint-url "$EP" \
  --source otp@example.com \
  --destination ToAddresses=user@example.com \
  --template otp \
  --template-data '{"code":"123456"}'
```

## Terraform

Green path: [`examples/terraform/ses/`](examples/terraform/ses/).

```hcl
endpoints {
  ses = var.simulith_endpoint
}
```

## Related

- Backlog:
- Study:
