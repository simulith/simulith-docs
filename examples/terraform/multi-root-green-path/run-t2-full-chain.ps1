# T2 manual verify - full eleven-step multi-root chain (bootstrap through 10-web)
$ErrorActionPreference = "Stop"
$Log = Join-Path $PSScriptRoot "t2-full-chain.log"
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
Write-Log "T2 full-chain start (eleven-step multi-root)"

$applyDirs = @(
    @{ Path = Join-Path $TfBase "s3/terraform-state-min"; Backend = $false },
    @{ Path = Join-Path $PSScriptRoot "01-vpc"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "02-subnets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "03-secrets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "04-postgresdb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "05-proxydb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "06-ses"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "07-cognito"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "08-parameters"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "09-dynamodb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "10-web"; Backend = $true }
)

foreach ($step in $applyDirs) {
    Invoke-TfStep -Dir $step.Path -Action apply -UseBackend:$step.Backend
}

Write-Log "APPLY phase complete - starting destroy"

$destroyDirs = @(
    @{ Path = Join-Path $PSScriptRoot "10-web"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "09-dynamodb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "08-parameters"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "07-cognito"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "06-ses"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "05-proxydb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "04-postgresdb"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "03-secrets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "02-subnets"; Backend = $true },
    @{ Path = Join-Path $PSScriptRoot "01-vpc"; Backend = $true },
    @{ Path = Join-Path $TfBase "s3/terraform-state-min"; Backend = $false }
)

foreach ($step in $destroyDirs) {
    Invoke-TfStep -Dir $step.Path -Action destroy -UseBackend:$step.Backend
}

Write-Log "T2 full-chain PASS"
