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
import {
  DeleteParameterCommand,
  GetParameterCommand,
  GetParametersByPathCommand,
  PutParameterCommand,
  SSMClient,
} from "@aws-sdk/client-ssm";

const endpoint = process.env.SIMULITH_ENDPOINT ?? "http://127.0.0.1:4566";
const region = process.env.AWS_DEFAULT_REGION ?? "us-east-1";

const SSM_PARAM_PATH = "/app/sdk-demo";
const SSM_PARAM_LOG_LEVEL = "/app/sdk-demo/log-level";
const SSM_PARAM_REGION = "/app/sdk-demo/region";

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
const runSSM = args.includes("--ssm");
const runSeed = args.includes("--seed");
const runAll = !runDynamoDB && !runSQS && !runSSM && !runSeed;

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

async function ssmSmoke() {
  const client = new SSMClient(clientConfig);

  for (const [name, value] of [
    [SSM_PARAM_LOG_LEVEL, "info"],
    [SSM_PARAM_REGION, "us-east-1"],
  ]) {
    await client.send(
      new PutParameterCommand({
        Name: name,
        Type: "String",
        Value: value,
        Overwrite: true,
      }),
    );
  }

  const byPath = await client.send(
    new GetParametersByPathCommand({
      Path: SSM_PARAM_PATH,
      Recursive: true,
    }),
  );
  if ((byPath.Parameters?.length ?? 0) < 2) {
    throw new Error(
      `get parameters by path: expected >=2 under ${SSM_PARAM_PATH}`,
    );
  }

  const got = await client.send(
    new GetParameterCommand({ Name: SSM_PARAM_LOG_LEVEL }),
  );
  if (got.Parameter?.Value !== "info") {
    throw new Error(`get parameter: unexpected value ${got.Parameter?.Value}`);
  }

  for (const name of [SSM_PARAM_LOG_LEVEL, SSM_PARAM_REGION]) {
    await client.send(new DeleteParameterCommand({ Name: name }));
  }
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

  const ssm = new SSMClient(clientConfig);
  const param = await ssm.send(
    new GetParameterCommand({ Name: "/app/demo/api-url" }),
  );
  if (!param.Parameter?.Value) {
    throw new Error("get seed parameter: empty (run simulith seed first)");
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
  if (runAll || runSSM) {
    await ssmSmoke();
    console.log("ssm: ok");
  }
  if (runAll || runSeed) {
    await seedSmoke();
    console.log("seed: ok");
  }
} catch (err) {
  fatal("example", err);
}
