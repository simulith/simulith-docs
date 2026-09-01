# Layer 4 - unmodified validator layer-transversal publish (Serverless build + Lambda layer APIs)
# Requires: VALIDATOR_LAYER_TRANSVERSAL_ROOT + Simulith on :4566
# Note: unmodified `serverless deploy` requires CloudFormation (not on Simulith). This script uses
#       the same build as deploy-backend.sh and PublishLayerVersion as the Simulith-equivalent path.
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-layer-transversal.log"
$LayerName = "layer-transversal"

$LayerRoot = $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT
if ([string]::IsNullOrWhiteSpace($LayerRoot)) {
    throw "Set VALIDATOR_LAYER_TRANSVERSAL_ROOT to the validator layer-transversal/ directory (local checkout only; not committed to simulith)."
}
if (-not (Test-Path $LayerRoot)) { throw "Path not found: $LayerRoot" }

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

function Invoke-BuildLayer {
    Write-Log "build start (Windows npx - same steps as npm run build:win)"
    Set-Location $LayerRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & npm install 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE)" }
        & npx rimraf ./layer/nodejs/node_modules 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        & npm install --production 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "npm install --production failed (exit $LASTEXITCODE)" }
        & npx shx mv -f node_modules ./layer/nodejs 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        & npx shx cp -r ./layer/nodejs/common ./layer/nodejs/node_modules 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        & npx shx cp -r ./layer/nodejs/controllers ./layer/nodejs/node_modules 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        & npx shx cp -r ./layer/nodejs/infrastructure ./layer/nodejs/node_modules 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK build"
}

function Get-LayerZipPath {
    $zipDir = Join-Path $LayerRoot ".serverless"
    $zipPath = Join-Path $zipDir "layer-transversal.zip"
    New-Item -ItemType Directory -Force -Path $zipDir | Out-Null
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Write-Log "zip layer/ -> $zipPath"
    Compress-Archive -Path (Join-Path $LayerRoot "layer\*") -DestinationPath $zipPath -Force
    Write-Log "zip size=$((Get-Item $zipPath).Length) bytes"
    return $zipPath
}

function Invoke-PublishLayer {
    Invoke-BuildLayer
    $zipPath = Get-LayerZipPath
    Write-Log "publish-layer-version layer=$LayerName"
    Set-Location $LayerRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & aws lambda publish-layer-version `
            --layer-name $LayerName `
            --zip-file "fileb://$zipPath" `
            --compatible-runtimes nodejs20.x `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "publish-layer-version failed (exit $LASTEXITCODE)" }
        & aws lambda list-layer-versions `
            --layer-name $LayerName `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "list-layer-versions failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK publish"
}

function Invoke-RemoveLayer {
    Write-Log "remove layer versions for $LayerName"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws lambda list-layer-versions `
            --layer-name $LayerName `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager `
            --output json 2>&1
        if ($LASTEXITCODE -ne 0) { throw "list-layer-versions failed (exit $LASTEXITCODE)" }
        $parsed = $json | ConvertFrom-Json
        foreach ($v in @($parsed.LayerVersions)) {
            $ver = $v.Version
            Write-Log "delete-layer-version $LayerName version $ver"
            & aws lambda delete-layer-version `
                --layer-name $LayerName `
                --version-number $ver `
                --endpoint-url $Endpoint `
                --region us-east-1 `
                --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            if ($LASTEXITCODE -ne 0) { throw "delete-layer-version $ver failed (exit $LASTEXITCODE)" }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "OK remove"
}

$sessionLine = "========== {0} L4 layer-transversal {1} start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 layer-transversal $Action start (root=$LayerRoot)"

switch ($Action) {
    "publish" { Invoke-PublishLayer }
    "remove"  { Invoke-RemoveLayer }
    "full" {
        Invoke-PublishLayer
        Invoke-RemoveLayer
    }
}

Write-Log "OK L4 layer-transversal $Action complete"
