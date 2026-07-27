# Changelog

All notable changes to Simulith are documented here. Versions follow
[Semantic Versioning](https://semver.org) and are managed automatically from
**merged stories** (`SML-###` + `Change type` in STORY-LOG) — see  /
.

Runtime and Console share a single version (one tag per release).

## [0.51.0] - 2026-07-27

### Features

- ****: Integration examples — S3 notification → Lambda CLI

## [0.50.0] - 2026-07-27

### Features

- ****: S3 object-create notification dispatch to Lambda

## [0.49.0] - 2026-07-27

### Features

- ****: S3 bucket notifications configuration

## [0.48.0] - 2026-07-27

### Features

- ****: S3 multipart upload

## [0.47.0] - 2026-07-25

### Features

- ****: Integration examples — Lambda Go provided.al2023 CLI

## [0.46.0] - 2026-07-25

### Features

- ****: Lambda Python layers PYTHONPATH

## [0.45.0] - 2026-07-24

### Features

- ****: Lambda Go runtime (provided bootstrap)

## [0.44.0] - 2026-07-24

### Features

- ****: SSM parameter policies / tier

## [0.43.0] - 2026-07-24

### Features

- ****: SDK examples — SSM parameter path

## [0.42.0] - 2026-07-24

### Features

- ****: Integration examples — SSM parameters path

## [0.41.0] - 2026-07-24

### Features

- ****: Integration examples (S3 object lifecycle CLI)

## [0.40.0] - 2026-07-23

### Features

- ****: Integration examples (DynamoDB + SQS fan-out)

## [0.39.0] - 2026-07-23

### Features

- ****: Integration examples (Secrets Manager + Lambda env)

## [0.38.0] - 2026-07-23

### Features

- ****: Honest integration examples (Lambda + API Gateway)

## [0.37.0] - 2026-07-23

### Features

- ****: Lambda UpdateFunctionConfiguration

## [0.36.0] - 2026-07-22

### Features

- ****: Seed demo secret

## [0.35.0] - 2026-07-22

### Features

- ****: Console Secrets Manager panel

## [0.34.0] - 2026-07-22

### Features

- ****: Terraform green path Secrets Manager

## [0.33.0] - 2026-07-22

### Features

- ****: simulith verify secretsmanager

## [0.32.0] - 2026-07-22

### Features

- ****: Parity release history

## [0.31.0] - 2026-07-22

### Features

- ****: Secrets Manager scaffold + Secret CRUD

## [0.30.0] - 2026-07-21

### Features

- ****: Seed demo API Gateway

## [0.29.0] - 2026-07-21

### Features

- ****: Console API Gateway panel

## [0.28.0] - 2026-07-18

### Features

- ****: Terraform green path API Gateway (runtime)

## [0.27.0] - 2026-07-17

### Features

- ****: simulith verify apigateway

## [0.26.0] - 2026-07-17

### Features

- ****: API Gateway deployment, stage, HTTP invoke (runtime)

## [0.25.0] - 2026-07-16

### Features

- ****: API Gateway resources + Lambda proxy integration (runtime)

## [0.24.0] - 2026-07-16

### Features

- ****: API Gateway scaffold + Rest API CRUD (runtime)

## [0.23.2] - 2026-07-15

### Fixes

- **Console**: Keep UI English regardless of browser locale (#268)

### Changed

- **Web & Console**: Add support contact email `simulithcloud@gmail.com` (#268)

### Documentation

- Public docs hygiene Phase 2 — sanitize mirror for end users (#267)

## [0.23.1] - 2026-07-15

### Fixes

- **n/a**: Parity smoke SQLite stability (#261, #264)

## [0.23.0] - 2026-07-13

### Features

- ****: Lambda Layers

## [0.22.0] - 2026-07-13

### Features

- ****: Lambda async invoke + Function URLs

## [0.21.0] - 2026-07-13

### Features

- ****: Lambda demo-fn in default seed

## [0.20.0] - 2026-07-13

### Features

- ****: Console Lambda panel

## [0.19.0] - 2026-07-13

### Features

- ****: Terraform green path Lambda

## [0.18.0] - 2026-07-13

### Features

- ****: simulith verify lambda

## [0.17.1] - 2026-07-10

### Fixes

- **PR-233**: Lambda list ESM routing before S3 path-style matching

## [0.17.0] - 2026-07-10

### Features

- ****: Lambda SQS event source mapping

## [0.16.0] - 2026-07-10

### Features

- ****: Lambda invoke sync subprocess

## [0.15.0] - 2026-07-09

### Features

- ****: Lambda service scaffold + Function CRUD

## [0.14.0] - 2026-07-08

### Features

- ****: Console Verify S3 parity

## [0.13.0] - 2026-07-08

### Features

- ****: S3 demo-bucket in default seed

## [0.12.0] - 2026-07-08

### Features

- ****: Console S3 panel

## [0.11.0] - 2026-07-08

### Features

- ****: S3 CopyObject and DeleteObjects

## [0.10.0] - 2026-07-07

### Features

- ****: Terraform green path S3

## [0.9.0] - 2026-07-07

### Features

- ****: simulith verify s3

## [0.8.0] - 2026-07-06

### Features

- ****: S3 ListObjectsV2

## [0.7.0] - 2026-07-06

### Features

- ****: S3 object CRUD

## [0.6.0] - 2026-07-06

### Features

- ****: S3 bucket lifecycle

## [0.5.0] - 2026-07-06

### Features

- ****: S3 service scaffold

## [0.4.1] - 2026-07-02

### Fixes

- ****: Corregir enlaces rotos en mirror simulith-docs (rewrite + fuente)

## [0.4.0] - 2026-07-01

### Features

- ****: Landing — SEO, meta y social cards

- ****: Landing — pruebas E2E (Cypress)

## [0.3.0] - 2026-07-01

### Features

- ****: Landing simulith.dev v1 (diseño + contenido pre-lanzamiento)

## [0.2.0] - 2026-07-01

### Features

- ****: Versionado automático de releases (semantic-release)

## [0.1.0] - 2026-06-30

Initial versioned release baseline.

- Release pipeline: multi-platform binaries + multi-arch runtime image, smoke, gated publish.
- Console release: multi-arch `simulith/console` image + published all-in-one compose.
