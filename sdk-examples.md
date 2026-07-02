# SDK examples — Simulith runtime

Copy-paste **AWS SDK** examples for MVP **DynamoDB** and **SQS** against Simulith.

> **New to Simulith?** Complete the [Quickstart](quickstart.md) first (run server, optional seed). For CLI equivalents see [AWS CLI examples](aws-cli-examples.md).

This guide is the **canonical SDK reference**. Runnable samples live in [`examples/go/`](examples/go/), [`examples/nodejs/`](examples/nodejs/), and [`examples/python/`](examples/python/).

---

## Prerequisites

- Simulith running on port **4566** ([quickstart](quickstart.md) — Docker or native)
- **Go 1.22+** (Go section), **Node.js 18+** (Node section), or **Python 3.10+** (Python section)
- Dummy credentials OK when SigV4 validation is off (default)

---

## Common configuration

Every SDK client needs the same three settings:

| Setting | Value |
| --- | --- |
| Endpoint | `http://127.0.0.1:4566` |
| Region | `us-east-1` |
| Credentials | access key `test`, secret `secret` (static) |

Optional environment (used by runnable examples):

```bash
export SIMULITH_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1
```

Docker users: reach the mapped port from the host the same way (`localhost:4566`).

---

## Go (AWS SDK v2)

Install dependencies (see [`examples/go/go.mod`](examples/go/go.mod)):

```bash
go get github.com/aws/aws-sdk-go-v2/config \
       github.com/aws/aws-sdk-go-v2/credentials \
       github.com/aws/aws-sdk-go-v2/service/dynamodb \
       github.com/aws/aws-sdk-go-v2/service/sqs
```

### Client setup

Pattern matches the internal compatibility runner (`internal/verify/dynamodb/client.go`):

```go
import (
    "context"

    "github.com/aws/aws-sdk-go-v2/aws"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/credentials"
    "github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

func newDynamoDBClient(ctx context.Context, region, endpoint string) (*dynamodb.Client, error) {
    cfg, err := config.LoadDefaultConfig(ctx,
        config.WithRegion(region),
        config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "secret", "")),
    )
    if err != nil {
        return nil, err
    }
    return dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
        o.BaseEndpoint = aws.String(endpoint)
    }), nil
}
```

SQS uses the same `LoadDefaultConfig` + `BaseEndpoint` pattern with `github.com/aws/aws-sdk-go-v2/service/sqs`.

### DynamoDB — CreateTable

```go
_, err := client.CreateTable(ctx, &dynamodb.CreateTableInput{
    TableName: aws.String("Music"),
    AttributeDefinitions: []types.AttributeDefinition{
        {AttributeName: aws.String("Artist"), AttributeType: types.ScalarAttributeTypeS},
    },
    KeySchema: []types.KeySchemaElement{
        {AttributeName: aws.String("Artist"), KeyType: types.KeyTypeHash},
    },
    BillingMode: types.BillingModePayPerRequest,
})
```

### DynamoDB — PutItem / GetItem

```go
_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
    TableName: aws.String("Music"),
    Item: map[string]types.AttributeValue{
        "Artist":     &types.AttributeValueMemberS{Value: "Acme Band"},
        "AlbumTitle": &types.AttributeValueMemberS{Value: "Songs About Life"},
    },
})

out, err := client.GetItem(ctx, &dynamodb.GetItemInput{
    TableName: aws.String("Music"),
    Key: map[string]types.AttributeValue{
        "Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
    },
})
```

### DynamoDB — Query / Scan / UpdateItem / DeleteItem

```go
_, err = client.Query(ctx, &dynamodb.QueryInput{
    TableName:              aws.String("Music"),
    KeyConditionExpression: aws.String("Artist = :a"),
    ExpressionAttributeValues: map[string]types.AttributeValue{
        ":a": &types.AttributeValueMemberS{Value: "Acme Band"},
    },
})

_, err = client.Scan(ctx, &dynamodb.ScanInput{TableName: aws.String("Music")})

_, err = client.UpdateItem(ctx, &dynamodb.UpdateItemInput{
    TableName: aws.String("Music"),
    Key: map[string]types.AttributeValue{
        "Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
    },
    UpdateExpression: aws.String("SET AlbumTitle = :t"),
    ExpressionAttributeValues: map[string]types.AttributeValue{
        ":t": &types.AttributeValueMemberS{Value: "Greatest Hits"},
    },
})

_, err = client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
    TableName: aws.String("Music"),
    Key: map[string]types.AttributeValue{
        "Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
    },
})
```

MVP includes `ListTables` — see [dynamodb.md](dynamodb.md#listtables-mvp).

See [dynamodb.md](dynamodb.md) for expression limits and AWS deviations.

### SQS — full message loop

Modern AWS SDKs use **AWS JSON 1.0** for SQS (`X-Amz-Target: AmazonSQS.CreateQueue`). The legacy Query protocol remains available for AWS CLI. Simulith supports both.

```go
import "github.com/aws/aws-sdk-go-v2/service/sqs"

createOut, err := sqsClient.CreateQueue(ctx, &sqs.CreateQueueInput{
    QueueName: aws.String("my-queue"),
})
queueURL := aws.ToString(createOut.QueueUrl)

_, err = sqsClient.SendMessage(ctx, &sqs.SendMessageInput{
    QueueUrl:    aws.String(queueURL),
    MessageBody: aws.String("hello from simulith"),
})

recvOut, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
    QueueUrl: aws.String(queueURL),
})
receipt := aws.ToString(recvOut.Messages[0].ReceiptHandle)

_, err = sqsClient.DeleteMessage(ctx, &sqs.DeleteMessageInput{
    QueueUrl:      aws.String(queueURL),
    ReceiptHandle: aws.String(receipt),
})
```

Queue URLs follow: `http://127.0.0.1:4566/000000000000/{queueName}`.

See [sqs.md](sqs.md) for protocol notes and error codes.

### Run the Go example

```bash
cd runtime/examples/go
go run .              # dynamodb + sqs smoke
go run . -seed        # after simulith seed
```

---

## Node.js (AWS SDK v3)

Install dependencies:

```bash
npm install @aws-sdk/client-dynamodb @aws-sdk/client-sqs
```

### Client setup

```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { SQSClient } from "@aws-sdk/client-sqs";

const clientConfig = {
  region: process.env.AWS_DEFAULT_REGION ?? "us-east-1",
  endpoint: process.env.SIMULITH_ENDPOINT ?? "http://127.0.0.1:4566",
  credentials: {
    accessKeyId: "test",
    secretAccessKey: "secret",
  },
};

const dynamodb = new DynamoDBClient(clientConfig);
const sqs = new SQSClient(clientConfig);
```

### DynamoDB — CreateTable

```javascript
import { CreateTableCommand } from "@aws-sdk/client-dynamodb";

await dynamodb.send(
  new CreateTableCommand({
    TableName: "Music",
    AttributeDefinitions: [{ AttributeName: "Artist", AttributeType: "S" }],
    KeySchema: [{ AttributeName: "Artist", KeyType: "HASH" }],
    BillingMode: "PAY_PER_REQUEST",
  }),
);
```

### DynamoDB — PutItem / GetItem

```javascript
import { GetItemCommand, PutItemCommand } from "@aws-sdk/client-dynamodb";

await dynamodb.send(
  new PutItemCommand({
    TableName: "Music",
    Item: {
      Artist: { S: "Acme Band" },
      AlbumTitle: { S: "Songs About Life" },
    },
  }),
);

const got = await dynamodb.send(
  new GetItemCommand({
    TableName: "Music",
    Key: { Artist: { S: "Acme Band" } },
  }),
);
```

### DynamoDB — Query / Scan / UpdateItem / DeleteItem

```javascript
import {
  DeleteItemCommand,
  QueryCommand,
  ScanCommand,
  UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";

await dynamodb.send(
  new QueryCommand({
    TableName: "Music",
    KeyConditionExpression: "Artist = :a",
    ExpressionAttributeValues: { ":a": { S: "Acme Band" } },
  }),
);

await dynamodb.send(new ScanCommand({ TableName: "Music" }));

await dynamodb.send(
  new UpdateItemCommand({
    TableName: "Music",
    Key: { Artist: { S: "Acme Band" } },
    UpdateExpression: "SET AlbumTitle = :t",
    ExpressionAttributeValues: { ":t": { S: "Greatest Hits" } },
  }),
);

await dynamodb.send(
  new DeleteItemCommand({
    TableName: "Music",
    Key: { Artist: { S: "Acme Band" } },
  }),
);
```

### SQS — full message loop

```javascript
import {
  CreateQueueCommand,
  DeleteMessageCommand,
  ReceiveMessageCommand,
  SendMessageCommand,
} from "@aws-sdk/client-sqs";

const created = await sqs.send(
  new CreateQueueCommand({ QueueName: "my-queue" }),
);
const queueUrl = created.QueueUrl;

await sqs.send(
  new SendMessageCommand({
    QueueUrl: queueUrl,
    MessageBody: "hello from simulith",
  }),
);

const received = await sqs.send(
  new ReceiveMessageCommand({ QueueUrl: queueUrl }),
);
const receipt = received.Messages[0].ReceiptHandle;

await sqs.send(
  new DeleteMessageCommand({
    QueueUrl: queueUrl,
    ReceiptHandle: receipt,
  }),
);
```

### Run the Node.js example

```bash
cd runtime/examples/nodejs
npm install
npm start             # dynamodb + sqs smoke
node index.mjs --seed # after simulith seed
```

---

## Python (boto3)

Install dependencies:

```bash
python -m pip install -r runtime/examples/python/requirements.txt
```

Or:

```bash
pip install boto3
```

### Client setup

```python
import os

import boto3
from botocore.config import Config

endpoint = os.environ.get("SIMULITH_ENDPOINT", "http://127.0.0.1:4566")
region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")

client_kwargs = {
    "endpoint_url": endpoint,
    "region_name": region,
    "aws_access_key_id": "test",
    "aws_secret_access_key": "secret",
    "config": Config(retries={"max_attempts": 2, "mode": "standard"}),
}

dynamodb = boto3.client("dynamodb", **client_kwargs)
sqs = boto3.client("sqs", **client_kwargs)
```

### DynamoDB — CreateTable

```python
dynamodb.create_table(
    TableName="Music",
    AttributeDefinitions=[{"AttributeName": "Artist", "AttributeType": "S"}],
    KeySchema=[{"AttributeName": "Artist", "KeyType": "HASH"}],
    BillingMode="PAY_PER_REQUEST",
)
```

### DynamoDB — PutItem / GetItem

```python
dynamodb.put_item(
    TableName="Music",
    Item={
        "Artist": {"S": "Acme Band"},
        "AlbumTitle": {"S": "Songs About Life"},
    },
)

got = dynamodb.get_item(
    TableName="Music",
    Key={"Artist": {"S": "Acme Band"}},
)
```

### DynamoDB — Query / Scan / UpdateItem / DeleteItem

```python
dynamodb.query(
    TableName="Music",
    KeyConditionExpression="Artist = :a",
    ExpressionAttributeValues={":a": {"S": "Acme Band"}},
)

dynamodb.scan(TableName="Music")

dynamodb.update_item(
    TableName="Music",
    Key={"Artist": {"S": "Acme Band"}},
    UpdateExpression="SET AlbumTitle = :t",
    ExpressionAttributeValues={":t": {"S": "Greatest Hits"}},
)

dynamodb.delete_item(
    TableName="Music",
    Key={"Artist": {"S": "Acme Band"}},
)
```

MVP includes `ListTables` — see [dynamodb.md](dynamodb.md#listtables-mvp).

### SQS — full message loop

Modern boto3 uses **AWS JSON 1.0** for SQS (`AmazonSQS.CreateQueue`). Simulith supports JSON and legacy Query (AWS CLI).

```python
created = sqs.create_queue(QueueName="my-queue")
queue_url = created["QueueUrl"]

sqs.send_message(QueueUrl=queue_url, MessageBody="hello from simulith")

received = sqs.receive_message(QueueUrl=queue_url)
receipt = received["Messages"][0]["ReceiptHandle"]

sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt)
```

Queue URLs follow: `http://127.0.0.1:4566/000000000000/{queueName}`.

See [sqs.md](sqs.md) for protocol notes and error codes.

### Run the Python example

```bash
cd runtime/examples/python
python -m pip install -r requirements.txt
python main.py              # dynamodb + sqs smoke
python main.py --seed       # after simulith seed
```

---

## Seeded data

After [`simulith seed`](seed.md) (Demo table + `demo-queue`):

**Go:**

```go
out, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
    TableName: aws.String("Demo"),
    Key: map[string]types.AttributeValue{
        "Id": &types.AttributeValueMemberS{Value: "1"},
    },
})

queueURL := endpoint + "/000000000000/demo-queue"
recvOut, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
    QueueUrl: aws.String(queueURL),
})
```

**Node.js:**

```javascript
const got = await dynamodb.send(
  new GetItemCommand({
    TableName: "Demo",
    Key: { Id: { S: "1" } },
  }),
);

const queueUrl = `${endpoint}/000000000000/demo-queue`;
const received = await sqs.send(
  new ReceiveMessageCommand({ QueueUrl: queueUrl }),
);
```

**Python:**

```python
got = dynamodb.get_item(TableName="Demo", Key={"Id": {"S": "1"}})

queue_url = f"{endpoint.rstrip('/')}/000000000000/demo-queue"
received = sqs.receive_message(QueueUrl=queue_url)
```

Expected: item name `Alice` (Id `1`); message body `hello from seed`.

CLI equivalent: [aws-cli-examples.md — Seeded data](aws-cli-examples.md#seeded-data).

---

## MVP limitations (summary)

| Area | Simulith MVP |
| --- | --- |
| DynamoDB ListTables | **Available** |
| DynamoDB GSI / LSI Query | Not supported |
| SQS FIFO queues | Not supported |
| SQS long polling | Short poll only |
| SQS SendMessageBatch / DeleteMessageBatch | Available (SML-039) |
| SSM Parameter Store | CLI/Terraform examples; runnable SDK samples (Go/Node/Python) deferred — see [ssm.md](ssm.md), [terraform-integration.md](terraform-integration.md), [examples/terraform/ssm/](examples/terraform/ssm/) |

Full deviation tables:

- [dynamodb.md — Local behavior deviations](dynamodb.md#local-behavior-deviations)
- [sqs.md — Deviations (MVP)](sqs.md#deviations-mvp)

---

## Related

- [quickstart.md](quickstart.md) — onboarding
- [aws-cli-examples.md](aws-cli-examples.md) — CLI cookbook
- [compatibility.md](compatibility.md) — `simulith verify dynamodb` (Go SDK internally)
- protocol.md — AWS JSON + Query wire formats
- [terraform-integration.md](terraform-integration.md) — Terraform / IaC cookbook
- smithy-contracts.md — API models
