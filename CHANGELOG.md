# Changelog

All notable changes to Simulith are documented here. Versions follow
[Semantic Versioning](https://semver.org) and are managed automatically from
**merged stories** (`SML-###` + `Change type` in STORY-LOG) — see  /
.

Runtime and Console share a single version (one tag per release).

## [0.119.0] - 2026-08-19

### Features

- ****: VPC NAT Gateway and IGW routes

## [0.118.0] - 2026-08-19

### Features

- ****: VPC interface endpoints

## [0.117.0] - 2026-08-19

### Features

- ****: S3 object version IDs

## [0.116.0] - 2026-08-19

### Features

- ****: Overlay-free remote state path-style

## [0.115.0] - 2026-08-19

### Features

- ****: STS GetCallerIdentity stub for remote state

## [0.114.0] - 2026-08-18

### Features

- ****: Overlay-free terraform_remote_state

## [0.113.0] - 2026-08-18

### Features

- ****: Unmodified multi-root Terraform apply

## [0.112.0] - 2026-08-15

### Features

- ****: Terraform remote-state bootstrap

## [0.111.2] - 2026-08-15

### Changed

- The published runtime image now packages the same binaries attached to this
  release, instead of compiling its own copy inside the container. `simulith version` in the image and in the downloaded archive
  can no longer disagree.

### Documentation

- Release pipeline: every GitHub Actions reference is pinned to a commit SHA
  and kept current by grouped Dependabot updates.

## [0.111.1] - 2026-08-14

### Fixes

- ****: Retry pushes to master instead of serializing story automation

## [0.111.0] - 2026-08-14

### Features

- ****: Terraform green path Lambda vpc-rds-proxy-min transaction probe

## [0.110.0] - 2026-08-14

### Features

- ****: Terraform web prod depth PAB policy apex alias

## [0.109.0] - 2026-08-14

### Features

- ****: Terraform green path vpc-rds-proxy-min single root

## [0.108.0] - 2026-08-14

### Features

- ****: Terraform green path vpc-rds-proxy-min single root

## [0.107.0] - 2026-08-14

### Features

- ****: Terraform green path web prod ACM viewer

## [0.106.1] - 2026-08-13

### Fixes

- ****: Terraform cdn-min apply/destroy green path

## [0.106.0] - 2026-08-13

### Features

- ****: Seed demo distribution

## [0.105.0] - 2026-08-13

### Features

- ****: Console CloudFront panel

## [0.104.0] - 2026-08-13

### Features

- ****: Terraform green path CloudFront

## [0.103.0] - 2026-08-13

### Features

- ****: simulith verify cloudfront

## [0.102.0] - 2026-08-13

### Features

- ****: CloudFront distribution + OAC slice

## [0.101.0] - 2026-08-12

### Features

- ****: Seed demo certificate

## [0.100.0] - 2026-08-12

### Features

- ****: Console ACM panel

## [0.99.0] - 2026-08-12

### Features

- ****: Terraform green path ACM

## [0.98.0] - 2026-08-12

### Features

- ****: simulith verify acm

## [0.97.0] - 2026-08-12

### Features

- ****: ACM certificate request + describe

## [0.96.0] - 2026-08-12

### Features

- ****: Seed demo hosted zone

## [0.95.0] - 2026-08-11

### Features

- ****: Terraform green path Route 53

## [0.94.0] - 2026-08-11

### Features

- ****: simulith verify route53

- ****: Console Route 53 panel

## [0.93.0] - 2026-08-10

### Features

- ****: Route 53 hosted zone + records scaffold

## [0.92.0] - 2026-08-10

### Features

- ****: KMS seed demo

- ****: IAM seed demo

## [0.91.0] - 2026-08-10

### Features

- ****: Console IAM panel

## [0.90.0] - 2026-08-10

### Features

- ****: Console KMS panel

## [0.89.0] - 2026-08-07

### Features

- ****: Terraform green path KMS

## [0.88.0] - 2026-08-07

### Features

- ****: simulith verify kms

## [0.87.0] - 2026-08-07

### Features

- ****: simulith verify iam

## [0.86.0] - 2026-08-07

### Features

- ****: VPC seed demo

## [0.85.0] - 2026-08-06

### Features

- ****: Release auto-close (continuous delivery)

## [0.84.0] - 2026-08-05

### Features

- ****: RDS seed demo

## [0.83.0] - 2026-08-05

### Features

- ****: Console RDS panel

## [0.82.0] - 2026-08-05

### Features

- ****: Console VPC panel

- ****: Terraform green path RDS

## [0.81.0] - 2026-08-05

### Features

- ****: Console VPC panel

## [0.80.0] - 2026-08-05

### Features

- ****: Terraform green path VPC

## [0.79.0] - 2026-08-04

### Features

- ****: simulith verify vpc

## [0.78.0] - 2026-08-04

### Features

- ****: simulith verify rds

## [0.77.0] - 2026-08-04

### Features

- ****: KMS CMK encrypt/decrypt

## [0.76.0] - 2026-08-03

### Features

- ****: Lambda VPC RDS reachability

## [0.75.0] - 2026-08-03

### Features

- ****: RDS Proxy sidecar

## [0.74.0] - 2026-08-03

### Features

- ****: IAM roles for RDS Proxy

## [0.73.0] - 2026-08-03

### Features

- ****: IAM roles for RDS Proxy

## [0.72.0] - 2026-08-03

### Features

- ****: RDS Postgres sidecar

## [0.71.0] - 2026-08-03

### Features

- ****: VPC subnets security groups scaffold

## [0.70.0] - 2026-08-02

### Features

- ****: EventBridge PutEvents

## [0.69.0] - 2026-08-01

### Features

- ****: Cognito Lambda triggers

## [0.68.0] - 2026-08-01

### Features

- ****: API Gateway Lambda request authorizer

## [0.67.0] - 2026-07-31

### Features

- ****: SES seed demo

## [0.66.0] - 2026-07-31

### Features

- ****: Console SES panel

## [0.65.0] - 2026-07-31

### Features

- ****: Cognito seed demo user pool

## [0.64.0] - 2026-07-30

### Features

- ****: Console Cognito panel

## [0.63.0] - 2026-07-30

### Features

- ****: EventBridge seed demo rule

## [0.62.0] - 2026-07-30

### Features

- ****: Console EventBridge panel

## [0.61.0] - 2026-07-29

### Features

- ****: simulith verify eventbridge

## [0.60.0] - 2026-07-29

### Features

- ****: simulith verify ses

## [0.59.0] - 2026-07-29

### Features

- ****: simulith verify cognito

## [0.58.0] - 2026-07-29

### Features

- ****: EventBridge schedule → Lambda invoke

## [0.57.0] - 2026-07-29

### Features

- ****: SES identity, template, SendTemplatedEmail

## [0.56.0] - 2026-07-29

### Features

- ****: Cognito Admin APIs

## [0.55.0] - 2026-07-28

### Features

- ****: Cognito User Pool

## [0.54.0] - 2026-07-28

### Features

- ****: Integration examples (Lambda Java CLI)

## [0.53.0] - 2026-07-28

### Features

- ****: Lambda Java runtime (subprocess)

## [0.52.0] - 2026-07-27

### Features

- ****: Seed demo S3 bucket notification to demo-fn

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
