# Simulith Runtime — Docker

Docker reference for the Simulith runtime. For first-time onboarding, see [quickstart.md](quickstart.md).

> **Releases (versioned images + binaries):** see [release.md](https://simulith.dev) — tag-driven pipeline, multi-arch image, smoke and gated publishing.

> **Docker Hub overviews (source):** [`../dockerhub/README.md`](https://hub.docker.com/r/simulith/simulith) — copy-paste README for `simulith/simulith` and `simulith/console` (SML-090 / FW-PRD-021).

Validation steps for SML-003: `cursor/analysis/features/_core/simulith-docker-support/test-checklist.md`

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

Runtime and Console are separate images that share the release version. See [release.md](https://simulith.dev).

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

## Configuration in containers

Compose sets environment variables (recommended for Docker):

| Variable | Compose value | Why |
| --- | --- | --- |
| `SIMULITH_HOST` | `0.0.0.0` | Required so port mapping reaches the process inside the container |
| `SIMULITH_PORT` | `4566` | Default MVP port |

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

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Port 4566 in use (LocalStack, etc.) | Change host port: `"8787:4566"` and `SIMULITH_PORT=8787` |
| Container unhealthy | `docker compose logs simulith`; confirm bind is `0.0.0.0` |
| Permission errors on bind mount | Ensure `./.simulith` is writable; named volume avoids most host permission issues |
| Stale image after code change | `docker compose up --build` or `docker build --no-cache` |

## Related

- [using-simulith.md](using-simulith.md) — **after Docker is running**: workflows, Simulith vs AWS, endpoint matrix
- [console.md](console.md) — all-in-one workshop demo
- [quickstart.md](quickstart.md) — onboarding
- [README.md](README.md) — module overview
- [`../dockerhub/README.md`](https://hub.docker.com/r/simulith/simulith) — Docker Hub repository overviews (source)
- `cursor/company/mvp-work-plan.md` — STORY-003
