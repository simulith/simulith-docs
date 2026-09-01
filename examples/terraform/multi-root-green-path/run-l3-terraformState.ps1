# Layer 3 - unmodified validator terraformState/ apply (isolated Terraform state)
# Requires: VALIDATOR_TERRAFORM_STATE_ROOT pointing at validator infrastructure/terraformState/
# Does not modify validator .tf or terraform.tfstate (uses -state in this directory).
param(
    [ValidateSet("apply", "destroy")]
    [string]$Action = "apply"
)

$ErrorActionPreference = "Stop"
$Log = Join-Path $PSScriptRoot "l3-terraformState.log"
$State = Join-Path $PSScriptRoot "l3-terraformState.tfstate"

$Root = $env:VALIDATOR_TERRAFORM_STATE_ROOT
if ([string]::IsNullOrWhiteSpace($Root)) {
    throw "Set VALIDATOR_TERRAFORM_STATE_ROOT to the validator terraformState/ directory (local checkout only; not committed to simulith)."
}
if (-not (Test-Path $Root)) {
    throw "VALIDATOR_TERRAFORM_STATE_ROOT not found: $Root"
}

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

if ($Action -eq "apply" -and -not (Test-Path $State)) {
    Write-Log "Using new isolated state: $State"
}

$OverrideSrc = Join-Path $PSScriptRoot "simulith.provider-override.tf.example"
$OverrideDst = Join-Path $Root "simulith_override.tf"

if (-not (Test-Path $OverrideSrc)) {
    throw "Missing provider override template: $OverrideSrc"
}
Copy-Item $OverrideSrc $OverrideDst -Force
Write-Log "Copied provider override to $OverrideDst"

Write-Log "L3 terraformState $Action start (root=$Root state=$State)"
Set-Location $Root

$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    & terraform init '-input=false' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw "init failed (exit $LASTEXITCODE)" }
    & terraform $Action "-state=$State" '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw "$Action failed (exit $LASTEXITCODE)" }
} finally {
    $ErrorActionPreference = $prevEap
}

Write-Log "OK L3 terraformState $Action"
