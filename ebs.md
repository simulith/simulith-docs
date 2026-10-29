# EBS (EC2 API) — Simulith

Metadata-only **EBS volumes** on the **EC2 Query API** (`:4566`, SigV4 service `ec2`). No block devices, snapshots, or real I/O.

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
