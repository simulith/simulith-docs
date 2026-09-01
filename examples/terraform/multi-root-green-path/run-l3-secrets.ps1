# Layer 3 - unmodified validator secrets/ apply (remote state from subnets/ on Simulith S3)
# Requires: VALIDATOR_SECRETS_ROOT, VALIDATOR_SUBNETS_ROOT, VALIDATOR_VPC_ROOT, VALIDATOR_TERRAFORM_STATE_ROOT
param(
    [ValidateSet("apply", "destroy", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l3-secrets.log"
$Backend = Join-Path $ScriptDir "backend.simulith.hcl"

$SecretsRoot = $env:VALIDATOR_SECRETS_ROOT
$SubnetsRoot = $env:VALIDATOR_SUBNETS_ROOT
$VpcRoot = $env:VALIDATOR_VPC_ROOT
$BootstrapRoot = $env:VALIDATOR_TERRAFORM_STATE_ROOT
if ([string]::IsNullOrWhiteSpace($SecretsRoot)) {
    throw "Set VALIDATOR_SECRETS_ROOT to the validator secrets/ directory (local checkout only; not committed to simulith)."
}
if ([string]::IsNullOrWhiteSpace($SubnetsRoot)) {
    throw "Set VALIDATOR_SUBNETS_ROOT to the validator subnets/ directory."
}
if ([string]::IsNullOrWhiteSpace($VpcRoot)) {
    throw "Set VALIDATOR_VPC_ROOT to the validator vpc/ directory."
}
if ([string]::IsNullOrWhiteSpace($BootstrapRoot)) {
    throw "Set VALIDATOR_TERRAFORM_STATE_ROOT to the validator terraformState/ directory."
}
foreach ($p in @($SecretsRoot, $SubnetsRoot, $VpcRoot, $BootstrapRoot)) {
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

function Invoke-Upstream([string]$UpstreamAction) {
    Write-Log "Upstream $UpstreamAction (via run-l3-subnets.ps1)"
    $env:VALIDATOR_SUBNETS_ROOT = $SubnetsRoot
    $env:VALIDATOR_VPC_ROOT = $VpcRoot
    $env:VALIDATOR_TERRAFORM_STATE_ROOT = $BootstrapRoot
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l3-subnets.ps1") -Action $UpstreamAction
    if ($LASTEXITCODE -ne 0) { throw "upstream $UpstreamAction failed (exit $LASTEXITCODE)" }
}

function Invoke-SecretsStep([string]$SecretsAction, [switch]$AllowFailure) {
    $OverrideSrc = Join-Path $ScriptDir "simulith.provider-override-secrets.tf.example"
    $OverrideDst = Join-Path $SecretsRoot "simulith_override.tf"
    Copy-Item $OverrideSrc $OverrideDst -Force
    Write-Log "Copied KMS/SM provider override to $OverrideDst"
    Write-Log "L3 secrets $SecretsAction start (root=$SecretsRoot)"
    Set-Location $SecretsRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & terraform init "-backend-config=$Backend" '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "secrets init failed (exit $LASTEXITCODE)" }
        $tfvars = Join-Path $SecretsRoot "dev.tfvars"
        if (-not (Test-Path $tfvars)) { throw "Missing dev.tfvars: $tfvars" }
        & terraform $SecretsAction "-var-file=$tfvars" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) {
            if ($AllowFailure) {
                Write-Log "WARN secrets $SecretsAction failed (exit $LASTEXITCODE) - continuing"
            } else {
                throw "secrets $SecretsAction failed (exit $LASTEXITCODE)"
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    if (-not $AllowFailure -or $LASTEXITCODE -eq 0) {
        Write-Log "OK L3 secrets $SecretsAction"
    }
}

$sessionLine = "========== {0} L3 secrets {1} start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action
try {
    "" | Set-Content $Log -ErrorAction Stop
} catch {
    Add-Content -Path $Log -Value $sessionLine
}
if (Test-Path $Log) {
    if ((Get-Item $Log).Length -eq 0) { Add-Content -Path $Log -Value $sessionLine }
}
Write-Log "L3 secrets $Action start"

switch ($Action) {
    "apply" {
        Invoke-Upstream "apply"
        Invoke-SecretsStep "destroy" -AllowFailure
        Invoke-SecretsStep "apply"
    }
    "destroy" {
        Invoke-SecretsStep "destroy"
        Invoke-Upstream "destroy"
    }
    "full" {
        Invoke-Upstream "apply"
        Invoke-SecretsStep "destroy" -AllowFailure
        Invoke-SecretsStep "apply"
        Invoke-SecretsStep "destroy"
        Invoke-Upstream "destroy"
    }
}

Write-Log "OK L3 secrets $Action complete"
