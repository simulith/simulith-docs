# Node.js SDK example — Simulith

Runnable smoke test using **AWS SDK for JavaScript v3** against a local Simulith endpoint.

## Prerequisites

- Simulith running on port **4566** — see [quickstart](../../docs/quickstart.md)
- Node.js 18+

## Run

```bash
cd runtime/examples/nodejs
npm install
npm start                 # dynamodb + sqs smoke
node index.mjs --dynamodb # DynamoDB Music workflow only
node index.mjs --sqs      # SQS message loop only
node index.mjs --seed     # Demo table + demo-queue (after simulith seed)
```

Optional environment:

```bash
export SIMULITH_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1
```

Full guide: [sdk-examples.md](../../docs/sdk-examples.md).
