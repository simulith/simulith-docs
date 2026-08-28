# T2 manual verify - SML-297 incremental 05-proxydb re-apply (UpdateRole)
$ErrorActionPreference = "Stop"
$Log = Join-Path $PSScriptRoot "t2-sml297.log"
$TfBase = Resolve-Path (Join-Path $PSScriptRoot "..")

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ENDPOINT_URL_S3 = $env:AWS_ENDPOINT_URL
$env:AWS_ENDPOINT_URL_DYNAMODB = $env:AWS_ENDPOINT_URL
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Log -Value $line
    Write-Output $line
}

function Invoke-TfStep {
    param(
        [string]$Dir,
        [ValidateSet("apply", "destroy")]
        [string]$Action,
        [switch]$UseBackend
    )
    Write-Log "$($Action.ToUpper()) $Dir"
    Set-Location $Dir
    if (Test-Path "terraform.tfvars.native.example") {
        Copy-Item "terraform.tfvars.native.example" "terraform.tfvars" -Force
    }
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($UseBackend) {
            & terraform init '-backend-config=backend.simulith.hcl' '-input=false' '-reconfigure' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        } else {
            & terraform init '-input=false' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        }
        if ($LASTEXITCODE -ne 0) { throw "init failed: $Dir (exit $LASTEXITCODE)" }
        & terraform $Action '-var-file=terraform.tfvars' '-parallelism=1' '-auto-approve' 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "$Action failed: $Dir (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK $Action $Dir"
}

"" | Set-Content $Log
Write-Log "T2 SML-297 start (UpdateRole incremental proxydb)"

$deps = @(
    @{ Path = Join-Path $TfBase "s3/terraform-state-min"; Backend = $false },
    @{ Path = Join-Path $PSScriptRoot "01-vpc"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "02-subnets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "03-secrets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "04-postgresdb"; Backend = $true }
)

foreach ($step in $deps) {
    Invoke-TfStep -Dir $step.Path -Action apply -UseBackend:$step.Backend
}

$proxydb = Join-Path $PSScriptRoot "05-proxydb"
Write-Log "First apply 05-proxydb (CreateRole path)"
Invoke-TfStep -Dir $proxydb -Action apply -UseBackend:$true

Write-Log "Second apply 05-proxydb (UpdateRole path - SML-297)"
Invoke-TfStep -Dir $proxydb -Action apply -UseBackend:$true

Write-Log "T2 SML-297 PASS"
