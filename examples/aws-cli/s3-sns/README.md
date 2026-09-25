# S3 → SNS bucket notification (Simulith)

Green path: create topic, bucket, `put-bucket-notification-configuration` with **TopicConfiguration**, `put-object`, inspect SNS message log.

**Prerequisite:** Simulith on `:4566`.

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://127.0.0.1:4566

./01-create-topic.sh
./02-create-bucket-and-notify.sh
./03-put-object.sh
```

See [`runtime/docs/s3.md`](../../../s3.md) · [`runtime/docs/sns.md`](../../../sns.md).
