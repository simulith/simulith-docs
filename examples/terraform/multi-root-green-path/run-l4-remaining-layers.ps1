# Layer 4 - unmodified validator layer-email / layer-otp / layer-engine publish
# Requires: VALIDATOR_LAYER_EMAIL_ROOT, VALIDATOR_LAYER_OTP_ROOT, VALIDATOR_LAYER_ENGINE_ROOT + Simulith :4566
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full",
    [ValidateSet("all", "email", "otp", "engine")]
    [string]$Layer = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-remaining-layers.log"

$LayerEmailRoot = $env:VALIDATOR_LAYER_EMAIL_ROOT
$LayerOtpRoot = $env:VALIDATOR_LAYER_OTP_ROOT
$LayerEngineRoot = $env:VALIDATOR_LAYER_ENGINE_ROOT
if ([string]::IsNullOrWhiteSpace($LayerEmailRoot)) {
    throw "Set VALIDATOR_LAYER_EMAIL_ROOT to the validator layer-email/ directory."
}
if ([string]::IsNullOrWhiteSpace($LayerOtpRoot)) {
    throw "Set VALIDATOR_LAYER_OTP_ROOT to the validator layer-otp/ directory."
}
if ([string]::IsNullOrWhiteSpace($LayerEngineRoot)) {
    throw "Set VALIDATOR_LAYER_ENGINE_ROOT to the validator layer-engine/ directory."
}
foreach ($p in @($LayerEmailRoot, $LayerOtpRoot, $LayerEngineRoot)) {
    if (-not (Test-Path $p)) { throw "Path not found: $p" }
}

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"
$Endpoint = $env:AWS_ENDPOINT_URL

$LayerSpecs = @(
    @{
        Key = "email"
        Name = "layer-email"
        Root = $LayerEmailRoot
        ZipFile = "layer-email.zip"
        ModuleDir = "email"
        ProductionOnly = $true
    },
    @{
        Key = "otp"
        Name = "layer-otp"
        Root = $LayerOtpRoot
        ZipFile = "layer-otp.zip"
        ModuleDir = "otp"
        ProductionOnly = $true
    },
    @{
        Key = "engine"
        Name = "layer-engine"
        Root = $LayerEngineRoot
        ZipFile = "layer-engine.zip"
        ModuleDir = "engine"
        ProductionOnly = $false
    }
)

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Log -Value $line -Encoding utf8
    Write-Host $line
}

function Get-SelectedLayers {
    if ($Layer -eq "all") { return $LayerSpecs }
    return @($LayerSpecs | Where-Object { $_.Key -eq $Layer })
}

function Invoke-BuildLayer([hashtable]$Spec) {
    Write-Log "$($Spec.Name) build start (Windows npx - build:win)"
    Set-Location $Spec.Root
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & npm install 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) npm install failed (exit $LASTEXITCODE)" }
        & npx rimraf ./layer/nodejs/node_modules 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($Spec.ProductionOnly) {
            & npm install --production 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        } else {
            & npm install 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        }
        if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) npm install deps failed (exit $LASTEXITCODE)" }
        & npx shx mv -f node_modules ./layer/nodejs 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        $moduleSrc = Join-Path $Spec.Root "layer\nodejs\$($Spec.ModuleDir)"
        $moduleDst = Join-Path $Spec.Root "layer\nodejs\node_modules"
        & npx shx cp -r $moduleSrc $moduleDst 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "$($Spec.Name) OK build"
}

function Get-LayerZipPath([hashtable]$Spec) {
    $zipDir = Join-Path $Spec.Root ".serverless"
    $zipPath = Join-Path $zipDir $Spec.ZipFile
    New-Item -ItemType Directory -Force -Path $zipDir | Out-Null
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Write-Log "$($Spec.Name) zip layer/ -> $zipPath"
    Compress-Archive -Path (Join-Path $Spec.Root "layer\*") -DestinationPath $zipPath -Force
    Write-Log "$($Spec.Name) zip size=$((Get-Item $zipPath).Length) bytes"
    return $zipPath
}

function Invoke-PublishOne([hashtable]$Spec) {
    Invoke-BuildLayer $Spec
    $zipPath = Get-LayerZipPath $Spec
    Write-Log "$($Spec.Name) publish-layer-version"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & aws lambda publish-layer-version `
            --layer-name $Spec.Name `
            --zip-file "fileb://$zipPath" `
            --compatible-runtimes nodejs20.x `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) publish-layer-version failed (exit $LASTEXITCODE)" }
        & aws lambda list-layer-versions `
            --layer-name $Spec.Name `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) list-layer-versions failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "$($Spec.Name) OK publish"
}

function Invoke-RemoveOne([hashtable]$Spec) {
    Write-Log "$($Spec.Name) remove layer versions"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws lambda list-layer-versions `
            --layer-name $Spec.Name `
            --endpoint-url $Endpoint `
            --region us-east-1 `
            --no-cli-pager `
            --output json 2>&1
        if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) list-layer-versions failed (exit $LASTEXITCODE)" }
        $parsed = $json | ConvertFrom-Json
        foreach ($v in @($parsed.LayerVersions)) {
            $ver = $v.Version
            Write-Log "$($Spec.Name) delete-layer-version $ver"
            & aws lambda delete-layer-version `
                --layer-name $Spec.Name `
                --version-number $ver `
                --endpoint-url $Endpoint `
                --region us-east-1 `
                --no-cli-pager 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            if ($LASTEXITCODE -ne 0) { throw "$($Spec.Name) delete-layer-version $ver failed (exit $LASTEXITCODE)" }
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Log "$($Spec.Name) OK remove"
}

$selected = Get-SelectedLayers
if ($selected.Count -eq 0) { throw "No layer selected: $Layer" }

$sessionLine = "========== {0} L4 remaining-layers {1} ({2}) start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action, $Layer
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 remaining-layers $Action ($Layer) start"

switch ($Action) {
    "publish" {
        foreach ($spec in $selected) { Invoke-PublishOne $spec }
    }
    "remove" {
        foreach ($spec in $selected) { Invoke-RemoveOne $spec }
    }
    "full" {
        foreach ($spec in $selected) { Invoke-PublishOne $spec }
        foreach ($spec in $selected) { Invoke-RemoveOne $spec }
    }
}

Write-Log "OK L4 remaining-layers $Action ($Layer) complete"
