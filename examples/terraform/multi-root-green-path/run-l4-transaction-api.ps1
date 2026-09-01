# Layer 4 - unmodified validator transaction-api deploy (6 functions via CreateFunction + VpcConfig)
# Requires: VALIDATOR_TRANSACTION_API_ROOT, VALIDATOR_LAYER_TRANSVERSAL_ROOT,
#           VALIDATOR_LAYER_OTP_ROOT, VALIDATOR_LAYER_ENGINE_ROOT + Simulith on :4566
# Upstream: layer-transversal, layer-otp, layer-engine; layer 3 SSM for VPC subnet/SG IDs
param(
    [ValidateSet("publish", "remove", "full")]
    [string]$Action = "full",
    [ValidateSet("all", "income", "expense", "points", "pointsExpiring", "history", "expirationJob")]
    [string]$Function = "all"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$Log = Join-Path $ScriptDir "l4-transaction-api.log"
$DummyRole = "arn:aws:iam::000000000000:role/r"
$SsmPrefix = "/LOYALEASY/DEV"

$TxRoot = $env:VALIDATOR_TRANSACTION_API_ROOT
$LayerTransRoot = $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT
$LayerOtpRoot = $env:VALIDATOR_LAYER_OTP_ROOT
$LayerEngineRoot = $env:VALIDATOR_LAYER_ENGINE_ROOT

foreach ($pair in @(
    @{ Name = "VALIDATOR_TRANSACTION_API_ROOT"; Value = $TxRoot }
    @{ Name = "VALIDATOR_LAYER_TRANSVERSAL_ROOT"; Value = $LayerTransRoot }
    @{ Name = "VALIDATOR_LAYER_OTP_ROOT"; Value = $LayerOtpRoot }
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
        Key = "income"
        Service = "income53rv1c3"
        Export = "income"
        Timeout = 10
        Layers = @("layer-transversal", "layer-engine")
        CopyItems = @(
            @{ Source = "functions\income\handler.js"; Dest = "handler.js" }
            @{ Source = "services\income"; Dest = "income" }
            @{ Source = "services\common"; Dest = "common" }
            @{ Source = "services\domain"; Dest = "domain" }
            @{ Source = "services\engine"; Dest = "engine" }
            @{ Source = "datamodel"; Dest = "datamodel" }
            @{ Source = "logs"; Dest = "logs" }
        )
    },
    @{
        Key = "expense"
        Service = "expense53rv1c3"
        Export = "expense"
        Timeout = 10
        Layers = @("layer-transversal", "layer-otp")
        CopyItems = @(
            @{ Source = "functions\expense\handler.js"; Dest = "handler.js" }
            @{ Source = "services\expense"; Dest = "expense" }
            @{ Source = "services\common"; Dest = "common" }
            @{ Source = "services\domain"; Dest = "domain" }
            @{ Source = "services\otp"; Dest = "otp" }
            @{ Source = "logs"; Dest = "logs" }
        )
    },
    @{
        Key = "points"
        Service = "points53rv1c3"
        Export = "points"
        Timeout = 10
        Layers = @("layer-transversal")
        CopyItems = @(
            @{ Source = "functions\points\handler.js"; Dest = "handler.js" }
            @{ Source = "services\points"; Dest = "points" }
            @{ Source = "logs"; Dest = "logs" }
        )
    },
    @{
        Key = "pointsExpiring"
        Service = "pointsExp53rv1c3"
        Export = "pointsExpiring"
        Timeout = 10
        Layers = @("layer-transversal")
        CopyItems = @(
            @{ Source = "functions\pointsExpiring\handler.js"; Dest = "handler.js" }
            @{ Source = "services\pointsExpiring"; Dest = "pointsExpiring" }
            @{ Source = "logs"; Dest = "logs" }
        )
    },
    @{
        Key = "history"
        Service = "history53rv1c3"
        Export = "history"
        Timeout = 10
        Layers = @("layer-transversal")
        CopyItems = @(
            @{ Source = "functions\history\handler.js"; Dest = "handler.js" }
            @{ Source = "services\history"; Dest = "history" }
            @{ Source = "services\income"; Dest = "income" }
            @{ Source = "logs"; Dest = "logs" }
        )
    },
    @{
        Key = "expirationJob"
        Service = "expirationJob53rv1c3"
        Export = "expirationJob"
        Timeout = 60
        Layers = @("layer-transversal")
        CopyItems = @(
            @{ Source = "functions\expirationJob\handler.js"; Dest = "handler.js" }
            @{ Source = "services\expirationJob"; Dest = "expirationJob" }
            @{ Source = "logs"; Dest = "logs" }
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

function Get-SsmValue([string]$Name) {
    $full = "{0}/{1}" -f $SsmPrefix, $Name
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $json = & aws ssm get-parameter --name $full --endpoint-url $Endpoint --region us-east-1 --no-cli-pager --output json 2>&1
        if ($LASTEXITCODE -ne 0) { throw "SSM get-parameter failed for $full (exit $LASTEXITCODE). Run layer 3 parameters/ first." }
        return (($json | ConvertFrom-Json).Parameter.Value)
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Get-VpcConfigArg {
    $subnets = @(
        (Get-SsmValue "DATABASE_SUBNET_4_ID")
        (Get-SsmValue "DATABASE_SUBNET_5_ID")
        (Get-SsmValue "DATABASE_SUBNET_6_ID")
    )
    $sgs = @(
        (Get-SsmValue "RDS_PROXY_SG")
        (Get-SsmValue "SECRETS_MANAGER_SG")
    )
    $subnetStr = ($subnets -join ",")
    $sgStr = ($sgs -join ",")
    Write-Log "vpc subnets=$subnetStr sgs=$sgStr"
    return "SubnetIds=$subnetStr,SecurityGroupIds=$sgStr"
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

function Invoke-EnsureLayers([string[]]$LayerNames) {
    $needTrans = $LayerNames -contains "layer-transversal"
    $needOtp = $LayerNames -contains "layer-otp"
    $needEngine = $LayerNames -contains "layer-engine"

    if ($needTrans -and -not (Test-LayerPublished "layer-transversal")) {
        Write-Log "upstream layer-transversal publish"
        $env:VALIDATOR_LAYER_TRANSVERSAL_ROOT = $LayerTransRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-layer-transversal.ps1") -Action publish
        if ($LASTEXITCODE -ne 0) { throw "upstream layer-transversal publish failed (exit $LASTEXITCODE)" }
    } elseif ($needTrans) {
        Write-Log "layer-transversal already published (skip rebuild)"
    }

    if ($needOtp -and -not (Test-LayerPublished "layer-otp")) {
        Write-Log "upstream layer-otp publish"
        if ([string]::IsNullOrWhiteSpace($env:VALIDATOR_LAYER_EMAIL_ROOT)) {
            $env:VALIDATOR_LAYER_EMAIL_ROOT = (Split-Path $LayerOtpRoot -Parent) + "\layer-email"
        }
        $env:VALIDATOR_LAYER_OTP_ROOT = $LayerOtpRoot
        $env:VALIDATOR_LAYER_ENGINE_ROOT = $LayerEngineRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-remaining-layers.ps1") -Action publish -Layer otp
        if ($LASTEXITCODE -ne 0) { throw "upstream layer-otp publish failed (exit $LASTEXITCODE)" }
    } elseif ($needOtp) {
        Write-Log "layer-otp already published (skip rebuild)"
    }

    if ($needEngine -and -not (Test-LayerPublished "layer-engine")) {
        Write-Log "upstream layer-engine publish"
        if ([string]::IsNullOrWhiteSpace($env:VALIDATOR_LAYER_EMAIL_ROOT)) {
            $env:VALIDATOR_LAYER_EMAIL_ROOT = (Split-Path $LayerEngineRoot -Parent) + "\layer-email"
        }
        $env:VALIDATOR_LAYER_OTP_ROOT = $LayerOtpRoot
        $env:VALIDATOR_LAYER_ENGINE_ROOT = $LayerEngineRoot
        & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-l4-remaining-layers.ps1") -Action publish -Layer engine
        if ($LASTEXITCODE -ne 0) { throw "upstream layer-engine publish failed (exit $LASTEXITCODE)" }
    } elseif ($needEngine) {
        Write-Log "layer-engine already published (skip rebuild)"
    }
}

function New-TransactionFunctionZip([hashtable]$Spec, [string]$ZipPath) {
    $tmpdir = Join-Path $env:TEMP ("l4-tx-pack-{0}" -f [Guid]::NewGuid().ToString("N"))
    $fnRoot = Join-Path $tmpdir "functions\$($Spec.Key)"
    New-Item -ItemType Directory -Force -Path $fnRoot | Out-Null
    try {
        foreach ($item in $Spec.CopyItems) {
            $src = Join-Path $TxRoot $item.Source
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

function Get-RequiredLayerNames {
    $names = New-Object System.Collections.Generic.HashSet[string]
    foreach ($spec in Get-SelectedSpecs) {
        foreach ($layer in $spec.Layers) { [void]$names.Add($layer) }
    }
    return @($names)
}

function Invoke-PublishTransactionApi {
    $requiredLayers = Get-RequiredLayerNames
    Invoke-EnsureLayers $requiredLayers
    $vpcConfig = Get-VpcConfigArg
    foreach ($spec in Get-SelectedSpecs) {
        $layerArns = @()
        foreach ($layerName in $spec.Layers) {
            $layerArns += Get-LayerVersionArn $layerName
        }
        $lambdaName = Get-LambdaName $spec
        $handler = Get-Handler $spec
        $zipPath = Join-Path $env:TEMP ("l4-transaction-api-{0}.zip" -f $spec.Key)
        New-TransactionFunctionZip $spec $zipPath
        Remove-LambdaIfExists $lambdaName
        Write-Log "create-function $lambdaName handler=$handler timeout=$($spec.Timeout) layers=$($layerArns -join ',')"
        $createArgs = @(
            "lambda", "create-function",
            "--function-name", $lambdaName,
            "--runtime", "nodejs20.x",
            "--handler", $handler,
            "--role", $DummyRole,
            "--zip-file", "fileb://$zipPath",
            "--timeout", "$($spec.Timeout)",
            "--memory-size", "128",
            "--vpc-config", $vpcConfig,
            "--endpoint-url", $Endpoint,
            "--region", "us-east-1",
            "--no-cli-pager"
        )
        if ($layerArns.Count -gt 0) {
            $createArgs += @("--layers") + $layerArns
        }
        Invoke-Aws $createArgs
        Invoke-Aws @("lambda", "get-function", "--function-name", $lambdaName, "--endpoint-url", $Endpoint, "--region", "us-east-1", "--no-cli-pager")
    }
    Write-Log "OK publish transaction-api"
}

function Invoke-RemoveTransactionApi {
    foreach ($spec in Get-SelectedSpecs) {
        Remove-LambdaIfExists (Get-LambdaName $spec)
    }
    Write-Log "OK remove transaction-api functions"
}

$sessionLine = "========== {0} L4 transaction-api {1} ({2}) start ==========" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Action, $Function
"" | Set-Content $Log -Encoding utf8
Add-Content -Path $Log -Value $sessionLine -Encoding utf8
Write-Log "L4 transaction-api $Action ($Function) start (root=$TxRoot)"

switch ($Action) {
    "publish" { Invoke-PublishTransactionApi }
    "remove"  { Invoke-RemoveTransactionApi }
    "full" {
        Invoke-PublishTransactionApi
        Invoke-RemoveTransactionApi
    }
}

Write-Log "OK L4 transaction-api $Action ($Function) complete"
