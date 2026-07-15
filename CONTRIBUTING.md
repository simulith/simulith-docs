# Contributing to simulith-docs

This repository is a **public mirror** of end-user documentation. It is not the source of truth.

## Where to change content

1. Edit docs in the private **`simulith/simulith`** monorepo under `runtime/docs/` and `runtime/examples/`.
2. Regenerate this mirror from the monorepo:

   ```bash
   cd runtime
   bash scripts/build-docs-mirror.sh
   ```

3. Copy the output (`runtime/dist/simulith-docs-mirror/`) into this repo and push.

See `runtime/docs/simulith-docs.md` in the monorepo for the full bootstrap and publish runbook.

## What not to do

- Do not treat pull requests here as the primary doc workflow (they will be overwritten on the next sync).
- Do not add internal backlog, sales-only, or maintainer release docs — those stay in the monorepo.

Automated sync on release: `.github/workflows/sync-simulith-docs.yml`. Set repo variable `DOCS_MIRROR_SYNC=true` and secret `SIMULITH_DOCS_SYNC_TOKEN`.
