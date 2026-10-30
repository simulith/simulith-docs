# Simulith on GitHub Actions

Simulith ships a composite GitHub Action at [`simulith/setup-action`](https://github.com/simulith/setup-action). It starts the runtime on a runner and exports the endpoint later steps pass to the AWS CLI or an SDK.

```yaml
- uses: simulith/setup-action@v0.309.2
- run: curl -fsS "$SIMULITH_ENDPOINT/health"
```

Pin `uses:` to a release tag. Guides and the compatibility matrix: [simulith-docs](https://github.com/simulith/simulith-docs).

## What the action sets

| Name | Value |
| --- | --- |
| `SIMULITH_ENDPOINT` | `http://127.0.0.1:4566` (or the `port` input) |
| `AWS_ENDPOINT_URL` | same URL |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `test` / `test` |
| `AWS_DEFAULT_REGION` | `us-east-1` unless `region` is set |
| `AWS_EC2_METADATA_DISABLED` | `true` |

```yaml
- uses: simulith/setup-action@v0.309.2
- run: aws dynamodb list-tables --endpoint-url "$SIMULITH_ENDPOINT"
```

Prefer `--endpoint-url "$SIMULITH_ENDPOINT"`. The action also sets `AWS_ENDPOINT_URL` for AWS CLI v2.

## Inputs

| Input | Default | Role |
| --- | --- | --- |
| `mode` | `docker` | `docker` or `binary` |
| `version` | `latest` | Image tag, or GitHub Release tag in binary mode |
| `image` | `simulith/simulith` | Image name (docker mode) |
| `port` | `4566` | Host port |
| `region` | `us-east-1` | Exported AWS region |
| `container-name` | `simulith` | Docker container name |
| `timeout-seconds` | `60` | Wait for `GET /health` |

## Outputs

| Output | Meaning |
| --- | --- |
| `endpoint-url` | `http://127.0.0.1:<port>` |
| `container-name` | Docker container name (docker mode) |

## Modes

| `mode` | Behavior |
| --- | --- |
| `docker` (default) | `docker run` of `image:version` (default `simulith/simulith:latest`). Host `port` maps to container port 4566. The process binds `0.0.0.0` via `SIMULITH_HOST`. |
| `binary` | Download the GitHub Release archive for the runner OS and architecture from [`simulith/setup-action`](https://github.com/simulith/setup-action/releases), verify `checksums.txt`, cache the binary, and run `simulith start --host 127.0.0.1 --port`. `version: latest` resolves the newest release before the cache key is chosen. |

```yaml
- uses: simulith/setup-action@v0.309.2
  with:
    mode: binary
    version: v0.309.2
```

No volume is mounted. State lasts for the job only. The action does not start the Console, and it does not mount the Docker socket (RDS sidecars and image-based Lambda need that separately — see [docker.md](docker.md)).
