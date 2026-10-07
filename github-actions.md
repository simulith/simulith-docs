# Simulith on GitHub Actions

Simulith ships a composite GitHub Action (`setup-action/` in the main repository) that starts the runtime on a runner and exports the endpoint later steps pass to the AWS CLI or an SDK.

```yaml
- uses: ./setup-action
- run: curl -fsS "$SIMULITH_ENDPOINT/health"
```

In the Simulith monorepo, workflows call `./setup-action`. A public repository can publish the same folder as `simulith/setup-action@<tag>` once the action repo is public. Pin third-party actions to a commit SHA; pin this action to a release tag or SHA when a public repo exists.

## What the action sets

| Name | Value |
| --- | --- |
| `SIMULITH_ENDPOINT` | `http://127.0.0.1:4566` (or the `port` input) |
| `AWS_ENDPOINT_URL` | same URL |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `test` / `test` |
| `AWS_DEFAULT_REGION` | `us-east-1` unless `region` is set |
| `AWS_EC2_METADATA_DISABLED` | `true` |

```yaml
- uses: ./setup-action
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
| `binary` | Download the GitHub Release archive for the runner OS and architecture, verify `checksums.txt`, cache the binary, and run `simulith start --host 127.0.0.1 --port`. `version: latest` resolves the newest release before the cache key is chosen. GitHub-hosted runners download with `gh release download` and the job token. |

```yaml
- uses: ./setup-action
  with:
    mode: binary
    version: v0.285.0
```

No volume is mounted. State lasts for the job only. The action does not start the Console, and it does not mount the Docker socket (RDS sidecars and image-based Lambda need that separately — see [docker.md](docker.md)).

## Marketplace

GitHub Marketplace lists an action whose `action.yml` is at the repository root. Until a public `simulith/setup-action` repository exists, only checkouts of the Simulith monorepo can use `uses: ./setup-action`. Publishing to Marketplace requires that public repo and accepting Marketplace terms in the GitHub UI.

## CI in the monorepo

The Simulith repository runs a **Setup action** workflow that builds `runtime/Dockerfile` and checks `/health` in docker mode, then checks `/health` in binary mode against the latest published release.
