# Layer 4 - unmodified validator auth-api deploy (Serverless package shape + Lambda CreateFunction)
# Requires: VALIDATOR_AUTH_API_ROOT + VALIDATOR_LAYER_TRANSVERSAL_ROOT + Simulith on :4566
# Upstream: publishes layer-transversal, then creates auth + authenticate Lambdas (Simulith-equivalent to serverless deploy).
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-auth-api.log"
$LayerName = "layer-transversal"
$FnAuth = "auth-api-auth-dev-auth"
$FnAuthenticate = "auth-api-authenticate-dev-authenticate"
$DummyRole = "arn:aws:iam::000000000000:role/r"

$AuthApiRoot = $env:VALIDATOR_AUTH_API_ROOT
$LayerRoot = $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT
if ([string]::IsNullOrWhiteSpace($AuthApiRoot)) {
    throw "Set VALIDATOR_AUTH_API_ROOT to the validator auth-api/ directory (local checkout only; not committed to simulith)."
}
if ([string]::IsNullOrWhiteSpace($LayerRoot)) {
    throw "Set VALIDATOR_LAYER_TRANSVERSAL_ROOT to the validator layer-transversal/ directory."
}
foreach ($p in @($AuthApiRoot, $LayerRoot)) {
    if (-not (Test-Path $p)) { throw "Path not found: $p" }
}

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"
$Endpoint = $env:AWS_ENDPOINT_URL

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Log -Value $line -Encoding utf8
    Write-Host $line
}

function Invoke-Aws([string[]]$AwsArgs) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & aws @AwsArgs 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "aws failed (exit $LASTEXITCODE): aws $($AwsArgs -join ' ')" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Get-LayerVersionArn {
    $json = & aws lambda list-layer-versions `
        --layer-name $LayerName `
        --endpoint-url $Endpoint `
        --region us-east-1 `
        --no-cli-pager `
        --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "list-layer-versions failed (exit $LASTEXITCODE)" }
    $parsed = $json | ConvertFrom-Json
    if (-not $parsed.LayerVersions -or $parsed.LayerVersions.Count -eq 0) {
        throw "No layer versions for $LayerName - run run-l4-layer-transversal.ps1 -Action publish first."
    }
    $latest = ($parsed.LayerVersions | Sort-Object Version -Descending | Select-Object -First 1).LayerVersionArn
    Write-Log "layer arn=$latest"
    return $latest
}

function Invoke-EnsureLayer {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws lambda list-layer-versions `
            --layer-name $LayerName `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager `
            --output json 2>&1
        if ($LASTEXITCODE -eq 0) {
            $parsed = $json | ConvertFrom-Json
            if ($parsed.LayerVersions -and $parsed.LayerVersions.Count -gt 0) {
                Write-Log "layer $LayerName already published (skip rebuild)"
                return
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "upstream layer-transversal publish"
    $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT = $LayerRoot
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-layer-transversal.ps1") -Action publish
    if ($LASTEXITCODE -ne 0) { throw "upstream layer publish failed (exit $LASTEXITCODE)" }
}

function New-FunctionZip([string]$FnDir, [string]$ServiceSubPath, [string]$ZipPath) {
    $tmpdir = Join-Path $env:TEMP ("l4-auth-pack-{0}" -f [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tmpdir | Out-Null
    try {
        $subName = Split-Path $ServiceSubPath -Leaf
        $destSub = Join-Path $tmpdir $subName
        New-Item -ItemType Directory -Force -Path $destSub | Out-Null
        Copy-Item (Join-Path $FnDir "handler.js") $tmpdir
        $src = Join-Path $AuthApiRoot $ServiceSubPath
        Copy-Item (Join-Path $src "*") $destSub -Recurse
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
        Compress-Archive -Path (Join-Path $tmpdir "*") -DestinationPath $ZipPath -Force
        Write-Log "zip $ZipPath size=$((Get-Item $ZipPath).Length) bytes"
    } finally {
        Remove-Item $tmpdir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Remove-LambdaIfExists([string]$Name) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & aws lambda get-function --function-name $Name --endpoint-url $Endpoint --region us-east-1 --no-cli-pager 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "delete-function $Name (pre-clean)"
            Invoke-Aws @("lambda", "delete-function", "--function-name", $Name, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Invoke-PublishAuthApi {
    Invoke-EnsureLayer
    $layerArn = Get-LayerVersionArn
    $zipAuth = Join-Path $env:TEMP "l4-auth-api-auth.zip"
    $zipAuthn = Join-Path $env:TEMP "l4-auth-api-authenticate.zip"
    New-FunctionZip (Join-Path $AuthApiRoot "functions\auth") "services\auth" $zipAuth
    New-FunctionZip (Join-Path $AuthApiRoot "functions\authenticate") "services\authenticate" $zipAuthn

    Remove-LambdaIfExists $FnAuth
    Write-Log "create-function $FnAuth"
    Invoke-Aws @(
        "lambda", "create-function",
        "--function-name", $FnAuth,
        "--runtime", "nodejs20.x",
        "--handler", "handler.auth",
        "--role", $DummyRole,
        "--zip-file", "fileb://$zipAuth",
        "--layers", $layerArn,
        "--timeout", "3",
        "--memory-size", "128",
        "--endpoint-url", $Endpoint,
        "--region", "us-east-1",
        "--no-cli-pager"
    )

    Remove-LambdaIfExists $FnAuthenticate
    Write-Log "create-function $FnAuthenticate"
    Invoke-Aws @(
        "lambda", "create-function",
        "--function-name", $FnAuthenticate,
        "--runtime", "nodejs20.x",
        "--handler", "handler.authenticate",
        "--role", $DummyRole,
        "--zip-file", "fileb://$zipAuthn",
        "--layers", $layerArn,
        "--timeout", "10",
        "--memory-size", "128",
        "--endpoint-url", $Endpoint,
        "--region", "us-east-1",
        "--no-cli-pager"
    )

    foreach ($fn in @($FnAuth, $FnAuthenticate)) {
        Write-Log "get-function $fn"
        Invoke-Aws @("lambda", "get-function", "--function-name", $fn, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
    }
    Write-Log "OK publish auth-api"
}

function Invoke-RemoveAuthApi {
    foreach ($fn in @($FnAuth, $FnAuthenticate)) {
        Remove-LambdaIfExists $fn
    }
    Write-Log "OK remove auth-api functions"
}

$sessionLine = "========== {0} L4 auth-api {1} start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 auth-api $Action start (root=$AuthApiRoot)"

switch ($Action) {
    "publish" { Invoke-PublishAuthApi }
    "remove"  { Invoke-RemoveAuthApi }
    "full" {
        Invoke-PublishAuthApi
        Invoke-RemoveAuthApi
        Write-Log "upstream layer-transversal remove"
        $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT = $LayerRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-layer-transversal.ps1") -Action remove
        if ($LASTEXITCODE -ne 0) { throw "upstream layer remove failed (exit $LASTEXITCODE)" }
    }
}

Write-Log "OK L4 auth-api $Action complete"
