# Layer 4 - unmodified validator engine-api deploy (3 functions via CreateFunction)
# Requires: VALIDATOR_ENGINE_API_ROOT, VALIDATOR_LAYER_TRANSVERSAL_ROOT, VALIDATOR_LAYER_ENGINE_ROOT + Simulith on :4566
# Upstream: layer-transversal + layer-engine; auth-api authorizer documented for HTTP (CreateFunction T2 does not require APIGW)
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full",
    [ValidateSet("all", "getRules", "updateRules", "executeRules")]
    [string]$Function = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-engine-api.log"
$DummyRole = "arn:aws:iam::000000000000:role/r"

$EngineApiRoot = $env:VALIDATOR_ENGINE_API_ROOT
$LayerTransRoot = $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT
$LayerEngineRoot = $env:VALIDATOR_LAYER_ENGINE_ROOT

foreach ($pair in @(
    @{ Name = "VALIDATOR_ENGINE_API_ROOT"; Value = $EngineApiRoot }
    @{ Name = "VALIDATOR_LAYER_TRANSVERSAL_ROOT"; Value = $LayerTransRoot }
    @{ Name = "VALIDATOR_LAYER_ENGINE_ROOT"; Value = $LayerEngineRoot }
)) {
    if ([string]::IsNullOrWhiteSpace($pair.Value)) {
        throw "Set $($pair.Name) to the validator checkout directory."
    }
    if (-not (Test-Path $pair.Value)) { throw "Path not found: $($pair.Value)" }
}

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"
$Endpoint = $env:AWS_ENDPOINT_URL

# dev.json service names -> Lambda function names (service-dev-export)
$FunctionSpecs = @(
    @{
        Key = "getRules"
        Service = "rulesGet53rv1c3"
        Export = "getRules"
        CopyItems = @(
            @{ Source = "functions\getRules\handler.js"; Dest = "handler.js" }
            @{ Source = "config"; Dest = "config" }
            @{ Source = "services\getRules"; Dest = "getRules" }
        )
    },
    @{
        Key = "updateRules"
        Service = "rulesPut53rv1c3"
        Export = "updateRules"
        CopyItems = @(
            @{ Source = "functions\updateRules\handler.js"; Dest = "handler.js" }
            @{ Source = "config"; Dest = "config" }
            @{ Source = "services\updateRules"; Dest = "updateRules" }
        )
    },
    @{
        Key = "executeRules"
        Service = "rulesPost53rv1c3"
        Export = "executeRules"
        CopyItems = @(
            @{ Source = "functions\executeRules\handler.js"; Dest = "handler.js" }
            @{ Source = "config"; Dest = "config" }
            @{ Source = "services\executeRules"; Dest = "executeRules" }
        )
    }
)

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Log -Value $line -Encoding utf8
    Write-Host $line
}

function Get-LambdaName([hashtable]$Spec) {
    return "{0}-dev-{1}" -f $Spec.Service, $Spec.Export
}

function Get-Handler([hashtable]$Spec) {
    return "functions/{0}/handler.{1}" -f $Spec.Key, $Spec.Export
}

function Invoke-Aws([string[]]$AwsArgs) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & aws @AwsArgs 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        if ($LASTEXITCODE -ne 0) { throw "aws failed (exit $LASTEXITCODE)" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Test-LayerPublished([string]$LayerName) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws lambda list-layer-versions --layer-name $LayerName --endpoint-url $Endpoint --region us-east-1 --no-cli-pager --output json 2>&1
        if ($LASTEXITCODE -ne 0) { return $false }
        $parsed = $json | ConvertFrom-Json
        return ($parsed.LayerVersions -and $parsed.LayerVersions.Count -gt 0)
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Get-LayerVersionArn([string]$LayerName) {
    $json = & aws lambda list-layer-versions --layer-name $LayerName --endpoint-url $Endpoint --region us-east-1 --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "list-layer-versions failed for $LayerName (exit $LASTEXITCODE)" }
    $parsed = $json | ConvertFrom-Json
    if (-not $parsed.LayerVersions -or $parsed.LayerVersions.Count -eq 0) {
        throw "No layer versions for $LayerName - publish upstream layers first."
    }
    return ($parsed.LayerVersions | Sort-Object Version -Descending | Select-Object -First 1).LayerVersionArn
}

function Invoke-EnsureLayers {
    if (-not (Test-LayerPublished "layer-transversal")) {
        Write-Log "upstream layer-transversal publish"
        $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT = $LayerTransRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-layer-transversal.ps1") -Action publish
        if ($LASTEXITCODE -ne 0) { throw "upstream layer-transversal publish failed (exit $LASTEXITCODE)" }
    } else {
        Write-Log "layer-transversal already published (skip rebuild)"
    }

    if (-not (Test-LayerPublished "layer-engine")) {
        Write-Log "upstream layer-engine publish"
        if ([string]::IsNullOrWhiteSpace($env:VALIDATOR_LAYER_EMAIL_ROOT)) {
            $env:VALIDATOR_LAYER_EMAIL_ROOT = (Split-Path $LayerEngineRoot -Parent) + "\layer-email"
        }
        if ([string]::IsNullOrWhiteSpace($env:VALIDATOR_LAYER_OTP_ROOT)) {
            $env:VALIDATOR_LAYER_OTP_ROOT = (Split-Path $LayerEngineRoot -Parent) + "\layer-otp"
        }
        $env:VALIDATOR_LAYER_ENGINE_ROOT = $LayerEngineRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-remaining-layers.ps1") -Action publish -Layer engine
        if ($LASTEXITCODE -ne 0) { throw "upstream layer-engine publish failed (exit $LASTEXITCODE)" }
    } else {
        Write-Log "layer-engine already published (skip rebuild)"
    }
}

function New-EngineFunctionZip([hashtable]$Spec, [string]$ZipPath) {
    $tmpdir = Join-Path $env:TEMP ("l4-engine-pack-{0}" -f [Guid]::NewGuid().ToString("N"))
    $fnRoot = Join-Path $tmpdir "functions\$($Spec.Key)"
    New-Item -ItemType Directory -Force -Path $fnRoot | Out-Null
    try {
        foreach ($item in $Spec.CopyItems) {
            $src = Join-Path $EngineApiRoot $item.Source
            $dest = Join-Path $fnRoot $item.Dest
            if (-not (Test-Path $src)) {
                Write-Log "skip missing path $($item.Source)"
                continue
            }
            if (Test-Path $src -PathType Container) {
                Copy-Item $src $dest -Recurse
            } else {
                $destDir = Split-Path $dest -Parent
                if ($destDir -and -not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
                }
                Copy-Item $src $dest
            }
        }
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
        Compress-Archive -Path (Join-Path $tmpdir "functions") -DestinationPath $ZipPath -Force
        Write-Log "$($Spec.Key) zip size=$((Get-Item $ZipPath).Length) bytes"
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
            Write-Log "delete-function $Name"
            Invoke-Aws @("lambda", "delete-function", "--function-name", $Name, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Get-SelectedSpecs {
    if ($Function -eq "all") { return $FunctionSpecs }
    return @($FunctionSpecs | Where-Object { $_.Key -eq $Function })
}

function Invoke-PublishEngineApi {
    Invoke-EnsureLayers
    $transArn = Get-LayerVersionArn "layer-transversal"
    $engineArn = Get-LayerVersionArn "layer-engine"
    Write-Log "layers transversal=$transArn engine=$engineArn"
    foreach ($spec in Get-SelectedSpecs) {
        $lambdaName = Get-LambdaName $spec
        $handler = Get-Handler $spec
        $zipPath = Join-Path $env:TEMP ("l4-engine-api-{0}.zip" -f $spec.Key)
        New-EngineFunctionZip $spec $zipPath
        Remove-LambdaIfExists $lambdaName
        Write-Log "create-function $lambdaName handler=$handler"
        Invoke-Aws @(
            "lambda", "create-function",
            "--function-name", $lambdaName,
            "--runtime", "nodejs20.x",
            "--handler", $handler,
            "--role", $DummyRole,
            "--zip-file", "fileb://$zipPath",
            "--layers", $transArn, $engineArn,
            "--timeout", "10",
            "--memory-size", "128",
            "--endpoint-url", $Endpoint,
            "--region", "us-east-1",
            "--no-cli-pager"
        )
        Invoke-Aws @("lambda", "get-function", "--function-name", $lambdaName, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
    }
    Write-Log "OK publish engine-api"
}

function Invoke-RemoveEngineApi {
    foreach ($spec in Get-SelectedSpecs) {
        Remove-LambdaIfExists (Get-LambdaName $spec)
    }
    Write-Log "OK remove engine-api functions"
}

$sessionLine = "========== {0} L4 engine-api {1} ({2}) start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action, $Function
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 engine-api $Action ($Function) start (root=$EngineApiRoot)"

switch ($Action) {
    "publish" { Invoke-PublishEngineApi }
    "remove"  { Invoke-RemoveEngineApi }
    "full" {
        Invoke-PublishEngineApi
        Invoke-RemoveEngineApi
    }
}

Write-Log "OK L4 engine-api $Action ($Function) complete"
