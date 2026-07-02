import {
  CreateTableCommand,
  DeleteItemCommand,
  DescribeTableCommand,
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  QueryCommand,
  ScanCommand,
  UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";
import {
  CreateQueueCommand,
  DeleteMessageCommand,
  ReceiveMessageCommand,
  SendMessageCommand,
  SQSClient,
} from "@aws-sdk/client-sqs";

const endpoint = process.env.SIMULITH_ENDPOINT ?? "http://127.0.0.1:4566";
const region = process.env.AWS_DEFAULT_REGION ?? "us-east-1";

const clientConfig = {
  region,
  endpoint,
  credentials: {
    accessKeyId: "test",
    secretAccessKey: "secret",
  },
};

const args = process.argv.slice(2);
const runDynamoDB = args.includes("--dynamodb");
const runSQS = args.includes("--sqs");
const runSeed = args.includes("--seed");
const runAll = !runDynamoDB && !runSQS && !runSeed;

function fatal(step, err) {
  console.error(`${step}:`, err.message ?? err);
  console.error("is Simulith running? see runtime/docs/quickstart.md");
  process.exit(1);
}

async function dynamoDBSmoke() {
  const client = new DynamoDBClient(clientConfig);
  const table = `Music-sdk-node-${Date.now() % 100000}`;

  await client.send(
    new CreateTableCommand({
      TableName: table,
      AttributeDefinitions: [{ AttributeName: "Artist", AttributeType: "S" }],
      KeySchema: [{ AttributeName: "Artist", KeyType: "HASH" }],
      BillingMode: "PAY_PER_REQUEST",
    }),
  );

  await client.send(new DescribeTableCommand({ TableName: table }));

  await client.send(
    new PutItemCommand({
      TableName: table,
      Item: {
        Artist: { S: "Acme Band" },
        AlbumTitle: { S: "Songs About Life" },
      },
    }),
  );

  const got = await client.send(
    new GetItemCommand({
      TableName: table,
      Key: { Artist: { S: "Acme Band" } },
    }),
  );
  if (!got.Item) {
    throw new Error("get item: empty result");
  }

  await client.send(
    new QueryCommand({
      TableName: table,
      KeyConditionExpression: "Artist = :a",
      ExpressionAttributeValues: { ":a": { S: "Acme Band" } },
    }),
  );

  await client.send(new ScanCommand({ TableName: table }));

  await client.send(
    new UpdateItemCommand({
      TableName: table,
      Key: { Artist: { S: "Acme Band" } },
      UpdateExpression: "SET AlbumTitle = :t",
      ExpressionAttributeValues: { ":t": { S: "Greatest Hits" } },
    }),
  );

  await client.send(
    new DeleteItemCommand({
      TableName: table,
      Key: { Artist: { S: "Acme Band" } },
    }),
  );
}

async function sqsSmoke() {
  const client = new SQSClient(clientConfig);
  const queueName = `sdk-node-queue-${Date.now() % 100000}`;

  const created = await client.send(
    new CreateQueueCommand({ QueueName: queueName }),
  );
  const queueUrl = created.QueueUrl;

  await client.send(
    new SendMessageCommand({
      QueueUrl: queueUrl,
      MessageBody: "hello from simulith node sdk",
    }),
  );

  const received = await client.send(
    new ReceiveMessageCommand({ QueueUrl: queueUrl }),
  );
  const message = received.Messages?.[0];
  if (!message?.ReceiptHandle) {
    throw new Error("receive message: empty result");
  }

  await client.send(
    new DeleteMessageCommand({
      QueueUrl: queueUrl,
      ReceiptHandle: message.ReceiptHandle,
    }),
  );
}

async function seedSmoke() {
  const ddb = new DynamoDBClient(clientConfig);
  const got = await ddb.send(
    new GetItemCommand({
      TableName: "Demo",
      Key: { Id: { S: "1" } },
    }),
  );
  if (!got.Item) {
    throw new Error("get demo item: empty (run simulith seed first)");
  }

  const sqs = new SQSClient(clientConfig);
  const queueUrl = `${endpoint}/000000000000/demo-queue`;
  const received = await sqs.send(
    new ReceiveMessageCommand({ QueueUrl: queueUrl }),
  );
  if (!received.Messages?.length) {
    throw new Error("receive seed message: empty (run simulith seed first)");
  }
}

try {
  if (runAll || runDynamoDB) {
    await dynamoDBSmoke();
    console.log("dynamodb: ok");
  }
  if (runAll || runSQS) {
    await sqsSmoke();
    console.log("sqs: ok");
  }
  if (runAll || runSeed) {
    await seedSmoke();
    console.log("seed: ok");
  }
} catch (err) {
  fatal("example", err);
}
