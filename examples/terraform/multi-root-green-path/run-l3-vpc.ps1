# Layer 3 - unmodified validator vpc/ apply (S3 backend on Simulith bootstrap bucket)
# Requires: VALIDATOR_VPC_ROOT, VALIDATOR_TERRAFORM_STATE_ROOT (bootstrap), bootstrap applied on Simulith
param(
    [ValidateSet("apply", "destroy", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l3-vpc.log"
$Backend = Join-Path $ScriptDir "backend.simulith.hcl"

$VpcRoot = $env:VALIDATOR_VPC_ROOT
$BootstrapRoot = $env:VALIDATOR_TERRAFORM_STATE_ROOT
if ([string]::IsNullOrWhiteSpace($VpcRoot)) {
    throw "Set VALIDATOR_VPC_ROOT to the validator vpc/ directory (local checkout only; not committed to simulith)."
}
if ([string]::IsNullOrWhiteSpace($BootstrapRoot)) {
    throw "Set VALIDATOR_TERRAFORM_STATE_ROOT to the validator terraformState/ directory."
}
if (-not (Test-Path $VpcRoot)) { throw "VALIDATOR_VPC_ROOT not found: $VpcRoot" }
if (-not (Test-Path $BootstrapRoot)) { throw "VALIDATOR_TERRAFORM_STATE_ROOT not found: $BootstrapRoot" }
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
    $prev = $env:VALIDATOR_TERRAFORM_STATE_ROOT
    $env:VALIDATOR_TERRAFORM_STATE_ROOT = $BootstrapRoot
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l3-terraformState.ps1") -Action $BootstrapAction
    if ($LASTEXITCODE -ne 0) { throw "bootstrap $BootstrapAction failed (exit $LASTEXITCODE)" }
    $env:VALIDATOR_TERRAFORM_STATE_ROOT = $prev
}

function Invoke-VpcStep([string]$VpcAction) {
    $OverrideSrc = Join-Path $ScriptDir "simulith.provider-override-vpc.tf.example"
    $OverrideDst = Join-Path $VpcRoot "simulith_override.tf"
    if (-not (Test-Path $OverrideSrc)) { throw "Missing VPC override template: $OverrideSrc" }
    Copy-Item $OverrideSrc $OverrideDst -Force
    Write-Log "Copied VPC provider override to $OverrideDst"
    Write-Log "L3 vpc $VpcAction start (root=$VpcRoot)"
    Set-Location $VpcRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & terraform init "-backend-config=$Backend" '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "vpc init failed (exit $LASTEXITCODE)" }
        $tfvars = Join-Path $VpcRoot "dev.tfvars"
        if (-not (Test-Path $tfvars)) { throw "Missing dev.tfvars: $tfvars" }
        & terraform $VpcAction "-var-file=$tfvars" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "vpc $VpcAction failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK L3 vpc $VpcAction"
}

"" | Set-Content $Log
Write-Log "L3 vpc $Action start"

switch ($Action) {
    "apply" {
        Invoke-Bootstrap "apply"
        Invoke-VpcStep "apply"
    }
    "destroy" {
        Invoke-VpcStep "destroy"
        Invoke-Bootstrap "destroy"
    }
    "full" {
        Invoke-Bootstrap "apply"
        Invoke-VpcStep "apply"
        Invoke-VpcStep "destroy"
        Invoke-Bootstrap "destroy"
    }
}

Write-Log "OK L3 vpc $Action complete"
