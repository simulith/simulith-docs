# Layer 4 - unmodified validator tenant-api deploy (8 functions via CreateFunction)
# Requires: VALIDATOR_TENANT_API_ROOT + VALIDATOR_LAYER_TRANSVERSAL_ROOT + Simulith on :4566
# Upstream: layer-transversal; auth-api authorizer documented for HTTP/API Gateway (CreateFunction T2 does not require APIGW)
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full",
    [ValidateSet("all", "tenants", "addTenant", "updateTenant", "officeByTenant", "addOfficeByTenant", "officeByTenantAndOfficeId", "updateOfficeByTenant", "generateApiKeyForTenant")]
    [string]$Function = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-tenant-api.log"
$LayerName = "layer-transversal"
$DummyRole = "arn:aws:iam::000000000000:role/r"

$TenantApiRoot = $env:VALIDATOR_TENANT_API_ROOT
$LayerRoot = $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT
if ([string]::IsNullOrWhiteSpace($TenantApiRoot)) {
    throw "Set VALIDATOR_TENANT_API_ROOT to the validator tenant-api/ directory."
}
if ([string]::IsNullOrWhiteSpace($LayerRoot)) {
    throw "Set VALIDATOR_LAYER_TRANSVERSAL_ROOT to the validator layer-transversal/ directory."
}
foreach ($p in @($TenantApiRoot, $LayerRoot)) {
    if (-not (Test-Path $p)) { throw "Path not found: $p" }
}

$env:AWS_ENDPOINT_URL = "http://127.0.0.1.sslip.io:4566"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "secret"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"
$Endpoint = $env:AWS_ENDPOINT_URL

# dev.json service names -> Lambda function names (service-dev-export)
$FunctionSpecs = @(
    @{ Key = "tenants"; Service = "tenantsGet53rv1c3"; Export = "tenants"; Folder = "tenants"; Domain = $true }
    @{ Key = "addTenant"; Service = "tenantsPost53rv1c3"; Export = "addTenant"; Folder = "addTenant"; Domain = $true }
    @{ Key = "updateTenant"; Service = "tenantsPut53rv1c3"; Export = "updateTenant"; Folder = "updateTenant"; Domain = $true }
    @{ Key = "officeByTenant"; Service = "officeGet53rv1c3"; Export = "officeByTenant"; Folder = "officeByTenant"; Domain = $true }
    @{ Key = "addOfficeByTenant"; Service = "officeAdd53rv1c3"; Export = "addOfficeByTenant"; Folder = "addOfficeByTenant"; Domain = $true }
    @{ Key = "officeByTenantAndOfficeId"; Service = "officeGetById53rv1c3"; Export = "officeByTenantAndOfficeId"; Folder = "officeByTenantAndOfficeId"; Domain = $true }
    @{ Key = "updateOfficeByTenant"; Service = "officeUpdate53rv1c3"; Export = "updateOfficeByTenant"; Folder = "updateOfficeByTenant"; Domain = $true }
    @{ Key = "generateApiKeyForTenant"; Service = "apiKeyPost53rv1c3"; Export = "generateApiKeyForTenant"; Folder = "generateApiKeyForTenant"; Domain = $true }
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

function Get-LayerVersionArn {
    $json = & aws lambda list-layer-versions --layer-name $LayerName --endpoint-url $Endpoint --region us-east-1 --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "list-layer-versions failed (exit $LASTEXITCODE)" }
    $parsed = $json | ConvertFrom-Json
    if (-not $parsed.LayerVersions -or $parsed.LayerVersions.Count -eq 0) {
        throw "No layer versions for $LayerName - run run-l4-layer-transversal.ps1 -Action publish first."
    }
    return ($parsed.LayerVersions | Sort-Object Version -Descending | Select-Object -First 1).LayerVersionArn
}

function Invoke-EnsureLayer {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws lambda list-layer-versions --layer-name $LayerName --endpoint-url $Endpoint --region us-east-1 --no-cli-pager --output json 2>&1
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

function New-TenantFunctionZip([hashtable]$Spec, [string]$ZipPath) {
    $tmpdir = Join-Path $env:TEMP ("l4-tenant-pack-{0}" -f [Guid]::NewGuid().ToString("N"))
    $fnRoot = Join-Path $tmpdir "functions\$($Spec.Key)"
    New-Item -ItemType Directory -Force -Path $fnRoot | Out-Null
    try {
        Copy-Item (Join-Path $TenantApiRoot "functions\$($Spec.Key)\handler.js") $fnRoot
        Copy-Item (Join-Path $TenantApiRoot "services\$($Spec.Folder)") (Join-Path $fnRoot $Spec.Folder) -Recurse
        if ($Spec.Domain) {
            Copy-Item (Join-Path $TenantApiRoot "services\domain") (Join-Path $fnRoot "domain") -Recurse
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

function Invoke-PublishTenantApi {
    Invoke-EnsureLayer
    $layerArn = Get-LayerVersionArn
    Write-Log "layer arn=$layerArn"
    foreach ($spec in Get-SelectedSpecs) {
        $lambdaName = Get-LambdaName $spec
        $handler = Get-Handler $spec
        $zipPath = Join-Path $env:TEMP ("l4-tenant-api-{0}.zip" -f $spec.Key)
        New-TenantFunctionZip $spec $zipPath
        Remove-LambdaIfExists $lambdaName
        Write-Log "create-function $lambdaName handler=$handler"
        Invoke-Aws @(
            "lambda", "create-function",
            "--function-name", $lambdaName,
            "--runtime", "nodejs20.x",
            "--handler", $handler,
            "--role", $DummyRole,
            "--zip-file", "fileb://$zipPath",
            "--layers", $layerArn,
            "--timeout", "10",
            "--memory-size", "128",
            "--endpoint-url", $Endpoint,
            "--region", "us-east-1",
            "--no-cli-pager"
        )
        Invoke-Aws @("lambda", "get-function", "--function-name", $lambdaName, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
    }
    Write-Log "OK publish tenant-api"
}

function Invoke-RemoveTenantApi {
    foreach ($spec in Get-SelectedSpecs) {
        Remove-LambdaIfExists (Get-LambdaName $spec)
    }
    Write-Log "OK remove tenant-api functions"
}

$sessionLine = "========== {0} L4 tenant-api {1} ({2}) start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action, $Function
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 tenant-api $Action ($Function) start (root=$TenantApiRoot)"

switch ($Action) {
    "publish" { Invoke-PublishTenantApi }
    "remove"  { Invoke-RemoveTenantApi }
    "full" {
        Invoke-PublishTenantApi
        Invoke-RemoveTenantApi
    }
}

Write-Log "OK L4 tenant-api $Action ($Function) complete"
