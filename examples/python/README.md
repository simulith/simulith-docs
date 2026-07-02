# Python SDK example — Simulith

Runnable smoke test using **boto3** against a local Simulith endpoint.

## Prerequisites

- Simulith running on port **4566** — see [quickstart](../../quickstart.md)
- Python 3.10+

## Run

```bash
cd runtime/examples/python
python -m pip install -r requirements.txt
python main.py                 # dynamodb + sqs smoke
python main.py --dynamodb      # DynamoDB Music workflow only
python main.py --sqs           # SQS message loop only
python main.py --seed          # Demo table + demo-queue (after simulith seed)
```

Optional environment:

```bash
export SIMULITH_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1
```

Full guide: [sdk-examples.md](../../sdk-examples.md).

Also see: [Go example](../go/README.md) · [Node.js example](../nodejs/README.md)
