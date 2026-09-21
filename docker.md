# Simulith Runtime — Docker

Docker reference for the Simulith runtime. For first-time onboarding, see [quickstart.md](quickstart.md).

> **Releases (versioned images + binaries):** see release.md — tag-driven pipeline, multi-arch image, smoke and gated publishing.

> **Docker Hub overviews (source):** [`../dockerhub/README.md`](https://hub.docker.com/r/simulith/simulith) — copy-paste README for `simulith/simulith` and `simulith/console`.

## Prerequisites

- Docker Desktop or Docker Engine 24+
- Docker Compose v2

## Compose layouts

| Use case | Command | Host URLs |
| --- | --- | --- |
| **Full product (published images)** | `docker compose -f docker-compose.all-in-one.published.yml up` | Console `http://localhost:9080` only |
| Workshop demo (build from repo) | `docker compose -f docker-compose.all-in-one.yml up --build` | Console `http://localhost:9080` only |
| Runtime only | `docker compose up --build` | AWS `http://localhost:4566` |
| Dev Console overlay | `-f docker-compose.yml -f docker-compose.console.yml up --build` | Console `:9080` + runtime `:4566` |

All-in-one details: [console.md](console.md) · Smoke: `maintainer workflow (private monorepo)`

### Full product from published images (no repo)

Pulls `simulith/simulith` + `simulith/console` (Docker Hub; GHCR mirror) — no checkout needed:

```bash
SIMULITH_VERSION=0.1.0 docker compose -f docker-compose.all-in-one.published.yml up
# or omit SIMULITH_VERSION for :latest
```

Runtime and Console are separate images that share the release version. See release.md.

## Quick run (runtime only)

```bash
cd /c/Projects/simulith/runtime
docker compose up --build
```

In another terminal:

```bash
curl http://localhost:4566/health
```

Expected: `{"status":"ok"}`

Check health status:

```bash
docker compose ps
```

The service should report **healthy** after the start period.

## Image build

```bash
docker build -t simulith:local .
docker run --rm -p 4566:4566 simulith:local
```

CI runs `docker build` on every PR (`.github/workflows/ci.yml` job `Runtime`).

Compose tags the runtime service `simulith-runtime:local` instead of the name it
would derive from the project directory. The fixed tag lets CI prebuild the image
against the shared layer cache; `scripts/ci-verify-smoke-docker.sh` then reuses it
rather than rebuilding. Locally nothing changes — compose builds the image when it
is missing, as before.

## Configuration in containers

Compose sets environment variables (recommended for Docker):

| Variable | Compose value | Why |
| --- | --- | --- |
| `SIMULITH_HOST` | `0.0.0.0` | Required so port mapping reaches the process inside the container |
| `SIMULITH_PORT` | `4566` | Listen port **inside** the container |
| `SIMULITH_RUNTIME_HOST_PORT` | `4566` | Host port published by Compose (`host:container`) |

**Pitfall:** If you mount a `config.yaml` with `server.host: 127.0.0.1`, the runtime binds to loopback **inside** the container and `curl localhost:4566` from the host will fail. Fixes:

- Keep using Compose env (`SIMULITH_HOST=0.0.0.0`), or
- Set `host: 0.0.0.0` in a Docker-specific config file, or
- Pass `--host 0.0.0.0` on the command line

Precedence: **flags > env > file > defaults** (see [quickstart.md](quickstart.md)).

## Persistence

### Named volume (default)

`docker-compose.yml` mounts a named volume at `/app/.simulith`:

```yaml
volumes:
  - simulith-data:/app/.simulith
```

Data survives `docker compose down` and container recreates. The SQLite state engine (Phase 3) will use `state.path: ./.simulith/state.db` relative to `/app`.

Verify volume after recreate:

```bash
docker compose up -d --build
docker compose down
docker compose up -d
curl http://localhost:4566/health
```

### Bind mount (optional, dev)

For host-visible state, uncomment in `docker-compose.yml`:

```yaml
# - ./.simulith:/app/.simulith
```

Create the directory on the host if needed. On Windows, ensure the path is shared with Docker Desktop.

## Container details

| Item | Value |
| --- | --- |
| Base image | `alpine:3.20` |
| User | `simulith` (non-root) |
| Workdir | `/app` |
| Entrypoint | `simulith start` |
| Health | `GET /health` via `wget` (Dockerfile + Compose) |

## Running multiple instances (parallel dev)

Run **separate containers** with different **host ports** and **volumes**. The process inside each container should keep `SIMULITH_PORT=4566`; only the Docker `-p` / Compose host mapping changes.

| Instance | Typical use | Host port | Volume | Container name |
| --- | --- | --- | --- | --- |
| **simulith-dev** | Simulith repo — verify, examples, CI | `4566` | `simulith-dev-data` | `simulith-dev` |
| **Customer / demoapp** | External checkout Path C + Serverless | `4567` | `simulith-demoapp-data` (or project-specific) | `simulith-demoapp` |

**Simulith repo (dev on `:4566`):**

```bash
cd runtime
docker compose up --build
# or published image:
docker run -d --name simulith-dev -p 4566:4566 \
  -v simulith-dev-data:/app/.simulith \
  -e SIMULITH_HOST=0.0.0.0 \
  simulith/simulith:latest
export SIMULITH_ENDPOINT=http://127.0.0.1:4566
```

**Second instance on `:4567` (same image, isolated state):**

```bash
docker run -d --name simulith-demoapp -p 4567:4566 \
  -v simulith-demoapp-data:/app/.simulith \
  -v //var/run/docker.sock:/var/run/docker.sock \
  -e SIMULITH_HOST=0.0.0.0 \
  simulith/simulith:latest
# Clients (AWS profile, Terraform backend, Serverless) → http://127.0.0.1.sslip.io:4567
```

**Compose on another host port:**

```bash
SIMULITH_RUNTIME_HOST_PORT=4567 docker compose up --build
# CLI still targets http://127.0.0.1:4567 (host), not SIMULITH_PORT inside the container
```

Customer-specific port conventions live in the **external** project (e.g. demoapp `.simulith.env`), not in Simulith defaults.

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Port 4566 in use (LocalStack, second instance, etc.) | Map a different **host** port: `-p 8787:4566` or `SIMULITH_RUNTIME_HOST_PORT=8787`. Keep **`SIMULITH_PORT=4566`** inside the container unless you also change the right-hand side of the port mapping. Clients use `http://127.0.0.1:8787`. |
| Container unhealthy | `docker compose logs simulith`; confirm bind is `0.0.0.0` |
| Permission errors on bind mount | Ensure `./.simulith` is writable; named volume avoids most host permission issues |
| Stale image after code change | `docker compose up --build` or `docker build --no-cache` |

## Related

- [using-simulith.md](using-simulith.md) — **after Docker is running**: workflows, Simulith vs AWS, endpoint matrix
- [serverless-integration.md](serverless-integration.md) — Serverless deploy with [`serverless-simulith`](https://www.npmjs.com/package/serverless-simulith) (npm)
- [console.md](console.md) — all-in-one workshop demo
- [quickstart.md](quickstart.md) — onboarding
- [README.md](README.md) — module overview
- [`../dockerhub/README.md`](https://hub.docker.com/r/simulith/simulith) — Docker Hub repository overviews (source)
-  — Docker support (Foundation phase)
