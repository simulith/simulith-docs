# Changelog

All notable changes to Simulith are documented here. Versions follow
[Semantic Versioning](https://semver.org) and are managed automatically from
**merged stories** (`SML-###` + `Change type` in STORY-LOG) — see SML-086 /
`cursor/scripts/sml-release.mjs`.

Runtime and Console share a single version (one tag per release).

## [0.17.1] - 2026-07-10

### Fixes

- **PR-233**: Lambda list ESM routing before S3 path-style matching

## [0.17.0] - 2026-07-10

### Features

- **SML-122**: Lambda SQS event source mapping

## [0.16.0] - 2026-07-10

### Features

- **SML-121**: Lambda invoke sync subprocess

## [0.15.0] - 2026-07-09

### Features

- **SML-120**: Lambda service scaffold + Function CRUD

## [0.14.0] - 2026-07-08

### Features

- **SML-116**: Console Verify S3 parity

## [0.13.0] - 2026-07-08

### Features

- **SML-114**: S3 demo-bucket in default seed

## [0.12.0] - 2026-07-08

### Features

- **SML-113**: Console S3 panel

## [0.11.0] - 2026-07-08

### Features

- **SML-112**: S3 CopyObject and DeleteObjects

## [0.10.0] - 2026-07-07

### Features

- **SML-111**: Terraform green path S3

## [0.9.0] - 2026-07-07

### Features

- **SML-110**: simulith verify s3

## [0.8.0] - 2026-07-06

### Features

- **SML-109**: S3 ListObjectsV2

## [0.7.0] - 2026-07-06

### Features

- **SML-108**: S3 object CRUD

## [0.6.0] - 2026-07-06

### Features

- **SML-107**: S3 bucket lifecycle

## [0.5.0] - 2026-07-06

### Features

- **SML-106**: S3 service scaffold

## [0.4.1] - 2026-07-02

### Fixes

- **SML-098**: Corregir enlaces rotos en mirror simulith-docs (rewrite + fuente)

## [0.4.0] - 2026-07-01

### Features

- **SML-088**: Landing — SEO, meta y social cards

- **SML-089**: Landing — pruebas E2E (Cypress)

## [0.3.0] - 2026-07-01

### Features

- **SML-087**: Landing simulith.dev v1 (diseño + contenido pre-lanzamiento)

## [0.2.0] - 2026-07-01

### Features

- **SML-086**: Versionado automático de releases (semantic-release)

## [0.1.0] - 2026-06-30

Initial versioned release baseline.

- Release pipeline: multi-platform binaries + multi-arch runtime image, smoke, gated publish (SML-084 / FW-PRD-017).
- Console release: multi-arch `simulith/console` image + published all-in-one compose (SML-085 / FW-PRD-018).
