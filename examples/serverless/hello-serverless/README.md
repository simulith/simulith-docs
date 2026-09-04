# Serverless — hello on Simulith

Minimal [Serverless Framework v3](https://www.serverless.com/) service: one HTTP Lambda + API Gateway REST API. Deploy and remove against Simulith on `:4566` without code changes.

Requires Simulith **≥ v0.157.0** plus  deploy hardening.

**Docker:** the runtime image includes Node.js so `nodejs20.x` functions invoke over API Gateway. Rebuild after pull: `docker compose up --build` or `docker build -t simulith/simulith:local runtime`.

## Prerequisites

- Node.js ≥ 18, npm
- Simulith running on `:4566` ([quickstart](../../../quickstart.md))
- AWS CLI v2 (for bucket bootstrap and smoke curl)

## Install

```bash
cd runtime/examples/serverless/hello-serverless
npm install
```

## Simulith endpoint

| How you run Simulith | Endpoint for CLI / Serverless |
| --- | --- |
| Docker runtime `:4566` | `http://127.0.0.1.sslip.io:4566` (Windows-friendly; also works as `http://127.0.0.1:4566`) |
| Native binary on host `:4566` | `http://127.0.0.1:4566` |

Set credentials (any non-empty values):

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566   # optional; plugin default matches
```

The example uses the **`serverless-simulith`** plugin (`custom.simulith` in `serverless.yml`) so Serverless deploy routes AWS SDK calls to Simulith. `provider.deploymentMethod: direct` avoids ChangeSet APIs Simulith does not implement yet.

## Bootstrap deployment bucket

Serverless uploads compiled templates and artifacts to S3. Create the bucket once per stage:

```bash
aws s3 mb s3://simulith-serverless-deploy-dev \
  --endpoint-url "$AWS_ENDPOINT_URL"
```

## Deploy

```bash
npm run deploy
# or: npx serverless deploy --stage dev
```

Expected: stack `hello-simulith-dev` reaches `CREATE_COMPLETE`, `serverless info` prints an API URL.

## Invoke (HTTP)

After deploy, open the `endpoints` URL from `serverless info`, or:

```bash
curl "$API_URL/hello"
# {"message":"hello from simulith"}
```

## Remove

```bash
npm run remove
```

Expected: stack and resources deleted. The CLI may exit non-zero if Serverless calls ECR cleanup APIs Simulith does not implement; verify with `aws cloudformation describe-stacks --stack-name hello-simulith-dev --endpoint-url …` (should report stack not found).

## Windows notes

- Prefer `127.0.0.1.sslip.io:4566` over bare `localhost` when virtual-hosted S3 bucket URLs are used.
- If a previous partial deploy left stack `hello-simulith-dev`, run `serverless remove` or `aws cloudformation delete-stack --stack-name hello-simulith-dev --endpoint-url …` before redeploying.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `The security token included in the request is invalid` | Plugin not active — add `serverless-simulith` and list stage under `custom.simulith.stages`. |
| `Could not locate deployment bucket` | Run the `aws s3 mb` bootstrap step for `simulith-serverless-deploy-dev`. |
| `Stack with id … does not exist` during monitor | Upgrade Simulith (DescribeStacks must accept stack ARN). |
| `delete … iam delete conflict` on update/remove | Upgrade Simulith (CFN delete order + inline policy cleanup). |
