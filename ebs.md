# EBS (EC2 API) — Simulith

Metadata-only **EBS volumes** on the **EC2 Query API** (`:4566`, SigV4 service `ec2`). No block devices, snapshots, or real I/O.

## EC2 SSH sidecar

**RunInstances** starts a real **OpenSSH container** on the Simulith host (pattern like RDS Postgres — **FW-EC2-020**). **Docker must be on PATH** where the runtime runs (mount `/var/run/docker.sock` in the hub image when using Console-in-Docker).

| SSH | Default |
| --- | --- |
| Host | `127.0.0.1` (`publicIp` / tag `simulith:ssh-port` on DescribeInstances) |
| Port | Published host port (tag `simulith:ssh-port`) |
| User | `ec2-user` (`SIMULITH_EC2_SSH_USER`) |
| Password | `simulith` (`SIMULITH_EC2_SSH_PASSWORD`) — **local dev only** |
| Image | Default `lscr.io/linuxserver/openssh-server:latest` (`SIMULITH_EC2_SSH_IMAGE`). Per-AMI map: `SIMULITH_EC2_AMI_MAP` JSON `{"ami-…":"docker.io/your/sshd:tag"}` or rich `{"ami-…":{"DockerImage":"…","ContainerSSHPort":2222}}` |
| AMI lookup | **`DescribeImages`** — catalog AMIs (`ami-0c02fb55956c7d316`, verify `ami-0123456789abcdef0`, `ami-local`) + synthetic entries for any `ami-*` in map or by id; filters `image-id`, `name`, `architecture`, `state`; `Owner=amazon|self` |

```bash
aws ec2 import-key-pair --endpoint-url "$AWS_ENDPOINT" \
  --key-name my-key --public-key-material fileb://~/.ssh/id_ed25519.pub

aws ec2 run-instances --endpoint-url "$AWS_ENDPOINT" \
  --image-id ami-local --instance-type t3.micro \
  --key-name my-key --user-data "$(echo -n 'touch /tmp/boot-marker' | base64)"

ssh -p "$PORT" ec2-user@127.0.0.1
```

**Key pairs:** `ImportKeyPair`, `DescribeKeyPairs`, `DeleteKeyPair` on the EC2 API — imported keys are injected into the SSH sidecar (`PUBLIC_KEY`). **`UserData`** runs in the container via `sh -c` after boot.

**Security groups:** If a group defines **ingress** rules, at least one must allow **TCP 22** (or all traffic). SGs with **ingress-only egress** (Terraform `instance-min` pattern) still allow local SSH on `127.0.0.1`.

`simulith verify ec2` scenario **`instance-ssh-sidecar`** dials the banner when Docker is available on the **Simulith host** (skips when sidecar cannot start).

## What you can do

| Operation | Notes |
| --- | --- |
| CreateVolume | Size (GiB), AvailabilityZone, VolumeType (default `gp3`), optional SnapshotId / Encrypted |
| DescribeVolumes | Filter by `VolumeId` or `volume-id` filter; attachments when linked to an instance |
| AttachVolume | Requires existing `VolumeId` + `InstanceId`; optional `Device` (default `/dev/sdf`); volume state `in-use` |
| DetachVolume | Clears attachment metadata; optional `InstanceId` must match |
| DeleteVolume | Fails with `VolumeInUse` while attached |

## What Simulith does not do

| Topic | Notes |
| --- | --- |
| Real block storage | No devices, I/O, or snapshots on disk |
| Snapshot lifecycle | No copy to S3, fast snapshot restore, or volume modification APIs |
| Multi-Attach data plane | Attachment metadata only |

## Terraform

Green path (with EC2 compute): [`examples/terraform/ec2/instance-min/`](examples/terraform/ec2/instance-min/) — `aws_ebs_volume` + `aws_volume_attachment`.

Verify: `simulith verify ec2 --skip-aws`.

Console: **EC2** panel → **EBS volumes** tab (CreateVolume / DescribeVolumes / DeleteVolume when not in-use). Attach/detach via CLI, SDK, or Terraform.
