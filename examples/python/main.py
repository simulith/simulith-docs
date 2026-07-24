#!/usr/bin/env python3
"""Simulith boto3 smoke — DynamoDB + SQS against local endpoint (FW-PRD-011 / SML-054)."""

from __future__ import annotations

import argparse
import os
import sys
import time

import boto3
from botocore.config import Config


def env_or(key: str, fallback: str) -> str:
    return os.environ.get(key) or fallback


def client_kwargs(endpoint: str, region: str) -> dict:
    return {
        "endpoint_url": endpoint,
        "region_name": region,
        "aws_access_key_id": "test",
        "aws_secret_access_key": "secret",
        "config": Config(retries={"max_attempts": 2, "mode": "standard"}),
    }


def run_dynamodb(endpoint: str, region: str) -> None:
    ddb = boto3.client("dynamodb", **client_kwargs(endpoint, region))
    table = f"Music-sdk-py-{int(time.time()) % 100000}"

    ddb.create_table(
        TableName=table,
        AttributeDefinitions=[{"AttributeName": "Artist", "AttributeType": "S"}],
        KeySchema=[{"AttributeName": "Artist", "KeyType": "HASH"}],
        BillingMode="PAY_PER_REQUEST",
    )
    ddb.describe_table(TableName=table)

    ddb.put_item(
        TableName=table,
        Item={
            "Artist": {"S": "Acme Band"},
            "AlbumTitle": {"S": "Songs About Life"},
        },
    )

    got = ddb.get_item(
        TableName=table,
        Key={"Artist": {"S": "Acme Band"}},
    )
    if "Item" not in got:
        raise RuntimeError("get item: empty result")

    ddb.query(
        TableName=table,
        KeyConditionExpression="Artist = :a",
        ExpressionAttributeValues={":a": {"S": "Acme Band"}},
    )
    ddb.scan(TableName=table)
    ddb.update_item(
        TableName=table,
        Key={"Artist": {"S": "Acme Band"}},
        UpdateExpression="SET AlbumTitle = :t",
        ExpressionAttributeValues={":t": {"S": "Greatest Hits"}},
    )
    ddb.delete_item(
        TableName=table,
        Key={"Artist": {"S": "Acme Band"}},
    )


def run_sqs(endpoint: str, region: str) -> None:
    sqs = boto3.client("sqs", **client_kwargs(endpoint, region))
    queue_name = f"sdk-py-queue-{int(time.time()) % 100000}"

    created = sqs.create_queue(QueueName=queue_name)
    queue_url = created["QueueUrl"]

    sqs.send_message(QueueUrl=queue_url, MessageBody="hello from simulith python sdk")

    received = sqs.receive_message(QueueUrl=queue_url)
    messages = received.get("Messages") or []
    if not messages:
        raise RuntimeError("receive message: empty result")

    sqs.delete_message(
        QueueUrl=queue_url,
        ReceiptHandle=messages[0]["ReceiptHandle"],
    )


SSM_PARAM_PATH = "/app/sdk-demo"
SSM_PARAM_LOG_LEVEL = "/app/sdk-demo/log-level"
SSM_PARAM_REGION = "/app/sdk-demo/region"


def run_ssm(endpoint: str, region: str) -> None:
    ssm = boto3.client("ssm", **client_kwargs(endpoint, region))

    for name, value in [
        (SSM_PARAM_LOG_LEVEL, "info"),
        (SSM_PARAM_REGION, "us-east-1"),
    ]:
        ssm.put_parameter(
            Name=name,
            Type="String",
            Value=value,
            Overwrite=True,
        )

    by_path = ssm.get_parameters_by_path(Path=SSM_PARAM_PATH, Recursive=True)
    if len(by_path.get("Parameters") or []) < 2:
        raise RuntimeError(f"get parameters by path: expected >=2 under {SSM_PARAM_PATH}")

    got = ssm.get_parameter(Name=SSM_PARAM_LOG_LEVEL)
    if got["Parameter"]["Value"] != "info":
        raise RuntimeError(f"get parameter: unexpected value {got['Parameter']['Value']}")

    for name in (SSM_PARAM_LOG_LEVEL, SSM_PARAM_REGION):
        ssm.delete_parameter(Name=name)


def run_seed(endpoint: str, region: str) -> None:
    ddb = boto3.client("dynamodb", **client_kwargs(endpoint, region))
    got = ddb.get_item(TableName="Demo", Key={"Id": {"S": "1"}})
    if "Item" not in got:
        raise RuntimeError("get demo item: empty (run simulith seed first)")

    sqs = boto3.client("sqs", **client_kwargs(endpoint, region))
    queue_url = f"{endpoint.rstrip('/')}/000000000000/demo-queue"
    received = sqs.receive_message(QueueUrl=queue_url)
    if not received.get("Messages"):
        raise RuntimeError("receive seed message: empty (run simulith seed first)")

    ssm = boto3.client("ssm", **client_kwargs(endpoint, region))
    param = ssm.get_parameter(Name="/app/demo/api-url")
    if not param.get("Parameter", {}).get("Value"):
        raise RuntimeError("get seed parameter: empty (run simulith seed first)")


def fatal(step: str, err: BaseException) -> None:
    print(f"{step}: {err}", file=sys.stderr)
    print("is Simulith running? see runtime/docs/quickstart.md", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Simulith boto3 SDK smoke")
    parser.add_argument("--dynamodb", action="store_true", help="DynamoDB Music workflow only")
    parser.add_argument("--sqs", action="store_true", help="SQS message loop only")
    parser.add_argument("--ssm", action="store_true", help="SSM parameter path workflow only")
    parser.add_argument("--seed", action="store_true", help="Demo table + demo-queue (after simulith seed)")
    args = parser.parse_args()

    run_all = not (args.dynamodb or args.sqs or args.ssm or args.seed)
    endpoint = env_or("SIMULITH_ENDPOINT", "http://127.0.0.1:4566")
    region = env_or("AWS_DEFAULT_REGION", "us-east-1")

    if run_all or args.dynamodb:
        try:
            run_dynamodb(endpoint, region)
            print("dynamodb: ok")
        except Exception as e:
            fatal("dynamodb", e)

    if run_all or args.sqs:
        try:
            run_sqs(endpoint, region)
            print("sqs: ok")
        except Exception as e:
            fatal("sqs", e)

    if run_all or args.ssm:
        try:
            run_ssm(endpoint, region)
            print("ssm: ok")
        except Exception as e:
            fatal("ssm", e)

    if run_all or args.seed:
        try:
            run_seed(endpoint, region)
            print("seed: ok")
        except Exception as e:
            fatal("seed", e)


if __name__ == "__main__":
    main()
