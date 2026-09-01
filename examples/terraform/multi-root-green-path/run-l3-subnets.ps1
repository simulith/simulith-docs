# Layer 3 - unmodified validator subnets/ apply (remote state from vpc/ on Simulith S3)
# Requires: VALIDATOR_SUBNETS_ROOT, VALIDATOR_VPC_ROOT, VALIDATOR_TERRAFORM_STATE_ROOT
param(
    [ValidateSet("apply", "destroy", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l3-subnets.log"
$Backend = Join-Path $ScriptDir "backend.simulith.hcl"

$SubnetsRoot = $env:VALIDATOR_SUBNETS_ROOT
$VpcRoot = $env:VALIDATOR_VPC_ROOT
$BootstrapRoot = $env:VALIDATOR_TERRAFORM_STATE_ROOT
if ([string]::IsNullOrWhiteSpace($SubnetsRoot)) {
    throw "Set VALIDATOR_SUBNETS_ROOT to the validator subnets/ directory (local checkout only; not committed to simulith)."
}
if ([string]::IsNullOrWhiteSpace($VpcRoot)) {
    throw "Set VALIDATOR_VPC_ROOT to the validator vpc/ directory."
}
if ([string]::IsNullOrWhiteSpace($BootstrapRoot)) {
    throw "Set VALIDATOR_TERRAFORM_STATE_ROOT to the validator terraformState/ directory."
}
foreach ($p in @($SubnetsRoot, $VpcRoot, $BootstrapRoot)) {
    if (-not (Test-Path $p)) { throw "Path not found: $p" }
}
if (-not (Test-Path $Backend)) { throw "Missing backend config: $Backend" }

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ENDPOINT_URL_S3 = $env:AWS_ENDPOINT_URL
$env:AWS_ENDPOINT_URL_DYNAMODB = $env:AWS_ENDPOINT_URL
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Log -Value $line
    Write-Output $line
}

function Invoke-Bootstrap([string]$BootstrapAction) {
    Write-Log "Bootstrap $BootstrapAction (via run-l3-terraformState.ps1)"
    $env:VALIDATOR_TERRAFORM_STATE_ROOT = $BootstrapRoot
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l3-terraformState.ps1") -Action $BootstrapAction
    if ($LASTEXITCODE -ne 0) { throw "bootstrap $BootstrapAction failed (exit $LASTEXITCODE)" }
}

function Invoke-Vpc([string]$VpcAction) {
    Write-Log "Vpc $VpcAction (via run-l3-vpc partial)"
    $OverrideSrc = Join-Path $ScriptDir "simulith.provider-override-vpc.tf.example"
    $OverrideDst = Join-Path $VpcRoot "simulith_override.tf"
    Copy-Item $OverrideSrc $OverrideDst -Force
    Set-Location $VpcRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & terraform init "-backend-config=$Backend" '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "vpc init failed (exit $LASTEXITCODE)" }
        $tfvars = Join-Path $VpcRoot "dev.tfvars"
        & terraform $VpcAction "-var-file=$tfvars" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "vpc $VpcAction failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK vpc $VpcAction"
}

function Invoke-SubnetsStep([string]$SubnetsAction) {
    $OverrideSrc = Join-Path $ScriptDir "simulith.provider-override-vpc.tf.example"
    $OverrideDst = Join-Path $SubnetsRoot "simulith_override.tf"
    Copy-Item $OverrideSrc $OverrideDst -Force
    Write-Log "Copied EC2 provider override to $OverrideDst"
    Write-Log "L3 subnets $SubnetsAction start (root=$SubnetsRoot)"
    Set-Location $SubnetsRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & terraform init "-backend-config=$Backend" '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "subnets init failed (exit $LASTEXITCODE)" }
        $tfvars = Join-Path $SubnetsRoot "dev.tfvars"
        if (-not (Test-Path $tfvars)) { throw "Missing dev.tfvars: $tfvars" }
        & terraform $SubnetsAction "-var-file=$tfvars" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "subnets $SubnetsAction failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK L3 subnets $SubnetsAction"
}

"" | Set-Content $Log
Write-Log "L3 subnets $Action start"

switch ($Action) {
    "apply" {
        Invoke-Bootstrap "apply"
        Invoke-Vpc "apply"
        Invoke-SubnetsStep "apply"
    }
    "destroy" {
        Invoke-SubnetsStep "destroy"
        Invoke-Vpc "destroy"
        Invoke-Bootstrap "destroy"
    }
    "full" {
        Invoke-Bootstrap "apply"
        Invoke-Vpc "apply"
        Invoke-SubnetsStep "apply"
        Invoke-SubnetsStep "destroy"
        Invoke-Vpc "destroy"
        Invoke-Bootstrap "destroy"
    }
}

Write-Log "OK L3 subnets $Action complete"
