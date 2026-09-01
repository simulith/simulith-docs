# Layer 3 - unmodified validator ses/ apply (standalone root; chains upstream for audit order)
# Requires: VALIDATOR_SES_ROOT, VALIDATOR_PROXYDB_ROOT, VALIDATOR_POSTGRESDB_ROOT, VALIDATOR_SECRETS_ROOT, VALIDATOR_SUBNETS_ROOT, VALIDATOR_VPC_ROOT, VALIDATOR_TERRAFORM_STATE_ROOT
# Requires: Docker (RDS sidecar for upstream proxydb chain) and Simulith on :4566
param(
    [ValidateSet("apply", "destroy", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l3-ses.log"
$Backend = Join-Path $ScriptDir "backend.simulith.hcl"

$SesRoot = $env:VALIDATOR_SES_ROOT
$ProxydbRoot = $env:VALIDATOR_PROXYDB_ROOT
$PostgresdbRoot = $env:VALIDATOR_POSTGRESDB_ROOT
$SecretsRoot = $env:VALIDATOR_SECRETS_ROOT
$SubnetsRoot = $env:VALIDATOR_SUBNETS_ROOT
$VpcRoot = $env:VALIDATOR_VPC_ROOT
$BootstrapRoot = $env:VALIDATOR_TERRAFORM_STATE_ROOT
if ([string]::IsNullOrWhiteSpace($SesRoot)) {
    throw "Set VALIDATOR_SES_ROOT to the validator ses/ directory (local checkout only; not committed to simulith)."
}
if ([string]::IsNullOrWhiteSpace($ProxydbRoot)) {
    throw "Set VALIDATOR_PROXYDB_ROOT to the validator proxydb/ directory."
}
if ([string]::IsNullOrWhiteSpace($PostgresdbRoot)) {
    throw "Set VALIDATOR_POSTGRESDB_ROOT to the validator postgresdb/ directory."
}
if ([string]::IsNullOrWhiteSpace($SecretsRoot)) {
    throw "Set VALIDATOR_SECRETS_ROOT to the validator secrets/ directory."
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
foreach ($p in @($SesRoot, $ProxydbRoot, $PostgresdbRoot, $SecretsRoot, $SubnetsRoot, $VpcRoot, $BootstrapRoot)) {
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
    Write-Log "Upstream $UpstreamAction (via run-l3-proxydb.ps1)"
    $env:VALIDATOR_PROXYDB_ROOT = $ProxydbRoot
    $env:VALIDATOR_POSTGRESDB_ROOT = $PostgresdbRoot
    $env:VALIDATOR_SECRETS_ROOT = $SecretsRoot
    $env:VALIDATOR_SUBNETS_ROOT = $SubnetsRoot
    $env:VALIDATOR_VPC_ROOT = $VpcRoot
    $env:VALIDATOR_TERRAFORM_STATE_ROOT = $BootstrapRoot
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l3-proxydb.ps1") -Action $UpstreamAction
    if ($LASTEXITCODE -ne 0) { throw "upstream $UpstreamAction failed (exit $LASTEXITCODE)" }
}

function Invoke-SesStep([string]$SesAction, [switch]$AllowFailure) {
    $OverrideSrc = Join-Path $ScriptDir "simulith.provider-override-ses.tf.example"
    $OverrideDst = Join-Path $SesRoot "simulith_override.tf"
    Copy-Item $OverrideSrc $OverrideDst -Force
    Write-Log "Copied SES provider override to $OverrideDst"
    Write-Log "L3 ses $SesAction start (root=$SesRoot)"
    Set-Location $SesRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & terraform init "-backend-config=$Backend" '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "ses init failed (exit $LASTEXITCODE)" }
        $tfvars = Join-Path $SesRoot "dev.tfvars"
        if (-not (Test-Path $tfvars)) { throw "Missing dev.tfvars: $tfvars" }
        & terraform $SesAction "-var-file=$tfvars" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) {
            if ($AllowFailure) {
                Write-Log "WARN ses $SesAction failed (exit $LASTEXITCODE) - continuing"
            } else {
                throw "ses $SesAction failed (exit $LASTEXITCODE)"
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    if (-not $AllowFailure -or $LASTEXITCODE -eq 0) {
        Write-Log "OK L3 ses $SesAction"
    }
}

$sessionLine = "========== {0} L3 ses {1} start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action
try {
    "" | Set-Content $Log -ErrorAction Stop
} catch {
    Add-Content -Path $Log -Value $sessionLine
}
if (Test-Path $Log) {
    if ((Get-Item $Log).Length -eq 0) { Add-Content -Path $Log -Value $sessionLine }
}
Write-Log "L3 ses $Action start"

switch ($Action) {
    "apply" {
        Invoke-Upstream "apply"
        Invoke-SesStep "destroy" -AllowFailure
        Invoke-SesStep "apply"
    }
    "destroy" {
        Invoke-SesStep "destroy"
        Invoke-Upstream "destroy"
    }
    "full" {
        Invoke-Upstream "apply"
        Invoke-SesStep "destroy" -AllowFailure
        Invoke-SesStep "apply"
        Invoke-SesStep "destroy"
        Invoke-Upstream "destroy"
    }
}

Write-Log "OK L3 ses $Action complete"
