# T2 manual verify - SML-299 standalone 10-web apply + destroy
$ErrorActionPreference = "Stop"
$Log = Join-Path $PSScriptRoot "t2-sml299.log"
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
Write-Log "T2 SML-299 start (standalone 10-web)"

Invoke-TfStep -Dir (Join-Path $TfBase "s3/terraform-state-min") -Action apply -UseBackend:$false
Invoke-TfStep -Dir (Join-Path $PSScriptRoot "10-web") -Action apply -UseBackend:$true
Invoke-TfStep -Dir (Join-Path $PSScriptRoot "10-web") -Action destroy -UseBackend:$true

Write-Log "T2 SML-299 PASS"
