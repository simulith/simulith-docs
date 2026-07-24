package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	ssmtypes "github.com/aws/aws-sdk-go-v2/service/ssm/types"
)

func main() {
	dynamodbFlag := flag.Bool("dynamodb", false, "run DynamoDB Music workflow")
	sqsFlag := flag.Bool("sqs", false, "run SQS message loop")
	ssmFlag := flag.Bool("ssm", false, "run SSM parameter path workflow")
	seedFlag := flag.Bool("seed", false, "read seeded Demo table and demo-queue")
	flag.Parse()

	runAll := !*dynamodbFlag && !*sqsFlag && !*ssmFlag && !*seedFlag

	endpoint := envOr("SIMULITH_ENDPOINT", "http://127.0.0.1:4566")
	region := envOr("AWS_DEFAULT_REGION", "us-east-1")
	ctx := context.Background()

	if runAll || *dynamodbFlag {
		if err := runDynamoDB(ctx, region, endpoint); err != nil {
			fatal("dynamodb", err)
		}
		fmt.Println("dynamodb: ok")
	}
	if runAll || *sqsFlag {
		if err := runSQS(ctx, region, endpoint); err != nil {
			fatal("sqs", err)
		}
		fmt.Println("sqs: ok")
	}
	if runAll || *ssmFlag {
		if err := runSSM(ctx, region, endpoint); err != nil {
			fatal("ssm", err)
		}
		fmt.Println("ssm: ok")
	}
	if runAll || *seedFlag {
		if err := runSeed(ctx, region, endpoint); err != nil {
			fatal("seed", err)
		}
		fmt.Println("seed: ok")
	}
}

func runDynamoDB(ctx context.Context, region, endpoint string) error {
	client, err := newDynamoDBClient(ctx, region, endpoint)
	if err != nil {
		return err
	}

	table := "Music-sdk-go-" + fmt.Sprintf("%d", time.Now().Unix()%100000)

	_, err = client.CreateTable(ctx, &dynamodb.CreateTableInput{
		TableName: aws.String(table),
		AttributeDefinitions: []types.AttributeDefinition{
			{AttributeName: aws.String("Artist"), AttributeType: types.ScalarAttributeTypeS},
		},
		KeySchema: []types.KeySchemaElement{
			{AttributeName: aws.String("Artist"), KeyType: types.KeyTypeHash},
		},
		BillingMode: types.BillingModePayPerRequest,
	})
	if err != nil {
		return fmt.Errorf("create table: %w", err)
	}

	_, err = client.DescribeTable(ctx, &dynamodb.DescribeTableInput{TableName: aws.String(table)})
	if err != nil {
		return fmt.Errorf("describe table: %w", err)
	}

	_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(table),
		Item: map[string]types.AttributeValue{
			"Artist":     &types.AttributeValueMemberS{Value: "Acme Band"},
			"AlbumTitle": &types.AttributeValueMemberS{Value: "Songs About Life"},
		},
	})
	if err != nil {
		return fmt.Errorf("put item: %w", err)
	}

	out, err := client.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(table),
		Key: map[string]types.AttributeValue{
			"Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
		},
	})
	if err != nil {
		return fmt.Errorf("get item: %w", err)
	}
	if out.Item == nil {
		return fmt.Errorf("get item: empty result")
	}

	_, err = client.Query(ctx, &dynamodb.QueryInput{
		TableName:              aws.String(table),
		KeyConditionExpression: aws.String("Artist = :a"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":a": &types.AttributeValueMemberS{Value: "Acme Band"},
		},
	})
	if err != nil {
		return fmt.Errorf("query: %w", err)
	}

	_, err = client.Scan(ctx, &dynamodb.ScanInput{TableName: aws.String(table)})
	if err != nil {
		return fmt.Errorf("scan: %w", err)
	}

	_, err = client.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName: aws.String(table),
		Key: map[string]types.AttributeValue{
			"Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
		},
		UpdateExpression: aws.String("SET AlbumTitle = :t"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":t": &types.AttributeValueMemberS{Value: "Greatest Hits"},
		},
	})
	if err != nil {
		return fmt.Errorf("update item: %w", err)
	}

	_, err = client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(table),
		Key: map[string]types.AttributeValue{
			"Artist": &types.AttributeValueMemberS{Value: "Acme Band"},
		},
	})
	if err != nil {
		return fmt.Errorf("delete item: %w", err)
	}

	return nil
}

func runSQS(ctx context.Context, region, endpoint string) error {
	client, err := newSQSClient(ctx, region, endpoint)
	if err != nil {
		return err
	}

	queueName := fmt.Sprintf("sdk-go-queue-%d", time.Now().Unix()%100000)
	createOut, err := client.CreateQueue(ctx, &sqs.CreateQueueInput{QueueName: aws.String(queueName)})
	if err != nil {
		return fmt.Errorf("create queue: %w", err)
	}
	queueURL := aws.ToString(createOut.QueueUrl)

	_, err = client.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    aws.String(queueURL),
		MessageBody: aws.String("hello from simulith go sdk"),
	})
	if err != nil {
		return fmt.Errorf("send message: %w", err)
	}

	recvOut, err := client.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
		QueueUrl: aws.String(queueURL),
	})
	if err != nil {
		return fmt.Errorf("receive message: %w", err)
	}
	if len(recvOut.Messages) == 0 {
		return fmt.Errorf("receive message: empty result")
	}
	receipt := aws.ToString(recvOut.Messages[0].ReceiptHandle)

	_, err = client.DeleteMessage(ctx, &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(queueURL),
		ReceiptHandle: aws.String(receipt),
	})
	if err != nil {
		return fmt.Errorf("delete message: %w", err)
	}

	return nil
}

const (
	ssmParamPath      = "/app/sdk-demo"
	ssmParamLogLevel  = "/app/sdk-demo/log-level"
	ssmParamRegionKey = "/app/sdk-demo/region"
)

func runSSM(ctx context.Context, region, endpoint string) error {
	client, err := newSSMClient(ctx, region, endpoint)
	if err != nil {
		return err
	}

	for _, p := range []struct {
		name, value string
	}{
		{ssmParamLogLevel, "info"},
		{ssmParamRegionKey, "us-east-1"},
	} {
		_, err = client.PutParameter(ctx, &ssm.PutParameterInput{
			Name:      aws.String(p.name),
			Type:      ssmtypes.ParameterTypeString,
			Value:     aws.String(p.value),
			Overwrite: aws.Bool(true),
		})
		if err != nil {
			return fmt.Errorf("put parameter %s: %w", p.name, err)
		}
	}

	pathOut, err := client.GetParametersByPath(ctx, &ssm.GetParametersByPathInput{
		Path:      aws.String(ssmParamPath),
		Recursive: aws.Bool(true),
	})
	if err != nil {
		return fmt.Errorf("get parameters by path: %w", err)
	}
	if len(pathOut.Parameters) < 2 {
		return fmt.Errorf("get parameters by path: expected >=2 under %s, got %d", ssmParamPath, len(pathOut.Parameters))
	}

	got, err := client.GetParameter(ctx, &ssm.GetParameterInput{
		Name: aws.String(ssmParamLogLevel),
	})
	if err != nil {
		return fmt.Errorf("get parameter: %w", err)
	}
	if aws.ToString(got.Parameter.Value) != "info" {
		return fmt.Errorf("get parameter: unexpected value %q", aws.ToString(got.Parameter.Value))
	}

	for _, name := range []string{ssmParamLogLevel, ssmParamRegionKey} {
		_, err = client.DeleteParameter(ctx, &ssm.DeleteParameterInput{Name: aws.String(name)})
		if err != nil {
			return fmt.Errorf("delete parameter %s: %w", name, err)
		}
	}

	return nil
}

func runSeed(ctx context.Context, region, endpoint string) error {
	ddb, err := newDynamoDBClient(ctx, region, endpoint)
	if err != nil {
		return err
	}

	out, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String("Demo"),
		Key: map[string]types.AttributeValue{
			"Id": &types.AttributeValueMemberS{Value: "1"},
		},
	})
	if err != nil {
		return fmt.Errorf("get demo item: %w", err)
	}
	if out.Item == nil {
		return fmt.Errorf("get demo item: empty (run simulith seed first)")
	}

	sqsClient, err := newSQSClient(ctx, region, endpoint)
	if err != nil {
		return err
	}

	queueURL := endpoint + "/000000000000/demo-queue"
	recvOut, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
		QueueUrl: aws.String(queueURL),
	})
	if err != nil {
		return fmt.Errorf("receive seed message: %w", err)
	}
	if len(recvOut.Messages) == 0 {
		return fmt.Errorf("receive seed message: empty (run simulith seed first)")
	}

	ssmClient, err := newSSMClient(ctx, region, endpoint)
	if err != nil {
		return err
	}
	paramOut, err := ssmClient.GetParameter(ctx, &ssm.GetParameterInput{
		Name: aws.String("/app/demo/api-url"),
	})
	if err != nil {
		return fmt.Errorf("get seed parameter: %w", err)
	}
	if aws.ToString(paramOut.Parameter.Value) == "" {
		return fmt.Errorf("get seed parameter: empty value")
	}

	return nil
}

func newDynamoDBClient(ctx context.Context, region, endpoint string) (*dynamodb.Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "secret", "")),
	)
	if err != nil {
		return nil, fmt.Errorf("load config: %w", err)
	}
	return dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
		o.BaseEndpoint = aws.String(endpoint)
	}), nil
}

func newSQSClient(ctx context.Context, region, endpoint string) (*sqs.Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "secret", "")),
	)
	if err != nil {
		return nil, fmt.Errorf("load config: %w", err)
	}
	return sqs.NewFromConfig(cfg, func(o *sqs.Options) {
		o.BaseEndpoint = aws.String(endpoint)
	}), nil
}

func newSSMClient(ctx context.Context, region, endpoint string) (*ssm.Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "secret", "")),
	)
	if err != nil {
		return nil, fmt.Errorf("load config: %w", err)
	}
	return ssm.NewFromConfig(cfg, func(o *ssm.Options) {
		o.BaseEndpoint = aws.String(endpoint)
	}), nil
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func fatal(step string, err error) {
	fmt.Fprintf(os.Stderr, "%s: %v\n", step, err)
	fmt.Fprintln(os.Stderr, "is Simulith running? see runtime/docs/quickstart.md")
	os.Exit(1)
}
