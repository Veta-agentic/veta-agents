<#
.SYNOPSIS
    Builds and deploys the veta-agents Docker image to Azure Web App for Containers.

.DESCRIPTION
    Builds the Docker image using the repo Dockerfile, pushes it to Azure Container
    Registry (ACR), updates the Web App container settings, and runs a basic health check.

    Resource values can be passed explicitly or auto-read from Terraform outputs.

.PARAMETER ResourceGroupName
    Azure Resource Group name containing the Web App.

.PARAMETER WebAppName
    Name of the Azure Web App.

.PARAMETER AcrName
    Name of the Azure Container Registry (without .azurecr.io).

.PARAMETER ImageTag
    Docker image tag. Default: latest.

.PARAMETER SkipBuild
    If set, skips Docker build and push — only updates Web App settings.

.PARAMETER TerraformOutputDir
    Path to Terraform directory to auto-read outputs. Overrides explicit params.

.EXAMPLE
    .\deploy-app.ps1 -ResourceGroupName "rsg-ghbot-123" -WebAppName "app-ghbot-123" -AcrName "crghbot123"

.EXAMPLE
    .\deploy-app.ps1 -TerraformOutputDir "..\..\iac\TF" -ImageTag "v1.2.0"

.EXAMPLE
    .\deploy-app.ps1 -TerraformOutputDir "..\..\iac\TF" -SkipBuild
#>

[CmdletBinding(DefaultParameterSetName = "Explicit")]
param(
    [Parameter(ParameterSetName = "Explicit", Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(ParameterSetName = "Explicit", Mandatory = $true)]
    [string]$WebAppName,

    [Parameter(ParameterSetName = "Explicit", Mandatory = $true)]
    [string]$AcrName,

    [Parameter(ParameterSetName = "Terraform", Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$TerraformOutputDir,

    [Parameter(Mandatory = $false)]
    [string]$ImageTag = "latest",

    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# ── Helper functions ────────────────────────────────────────────────────────

function Write-Status  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Failure { param([string]$Message) Write-Host "[FAIL]  $Message" -ForegroundColor Red }
function Write-Step    { param([string]$Message) Write-Host "`n═══ $Message ═══" -ForegroundColor Yellow }

function Test-Command {
    param([string]$Name, [string]$InstallUrl)
    try {
        $null = Get-Command $Name -ErrorAction Stop
        Write-Success "$Name is available"
        return $true
    }
    catch {
        Write-Failure "$Name is not installed. See: $InstallUrl"
        return $false
    }
}

# ── Prerequisites ───────────────────────────────────────────────────────────

Write-Step "Checking Prerequisites"

$dockerOk = Test-Command "docker" "https://docs.docker.com/get-docker/"
$azOk     = Test-Command "az"     "https://learn.microsoft.com/cli/azure/install-azure-cli"

if (-not $dockerOk -or -not $azOk) {
    Write-Failure "Missing required tools. Install them and retry."
    exit 1
}

# ── Resolve parameters from Terraform outputs ──────────────────────────────

if ($PSCmdlet.ParameterSetName -eq "Terraform") {
    Write-Step "Reading Terraform Outputs"

    Push-Location $TerraformOutputDir
    try {
        $tfOutputJson = terraform output -json 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Failure "Failed to read terraform outputs from: $TerraformOutputDir"
            exit 1
        }
        $tfOutputs = $tfOutputJson | ConvertFrom-Json

        $ResourceGroupName = $tfOutputs.resource_group_name.value
        $WebAppName        = $tfOutputs.web_app_name.value
        $AcrName           = $tfOutputs.container_registry_name.value
        $webAppUrl         = $tfOutputs.web_app_default_hostname.value

        Write-Success "Resource Group : $ResourceGroupName"
        Write-Success "Web App        : $WebAppName"
        Write-Success "ACR            : $AcrName"
        Write-Success "Web App URL    : $webAppUrl"
    }
    finally {
        Pop-Location
    }
}

# ── Derive values ───────────────────────────────────────────────────────────

$acrLoginServer = "$AcrName.azurecr.io"
$imageName      = "veta-agents"
$fullImageRef   = "${acrLoginServer}/${imageName}:${ImageTag}"

$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = Split-Path $PSScriptRoot -Parent }

# ── ACR Login ───────────────────────────────────────────────────────────────

Write-Step "ACR Login"

az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) { Write-Failure "ACR login failed."; exit 1 }
Write-Success "Logged in to $acrLoginServer"

# ── Docker Build & Push ─────────────────────────────────────────────────────

if ($SkipBuild) {
    Write-Status "SkipBuild flag set — skipping Docker build and push."
}
else {
    Write-Step "Docker Build"
    Write-Status "Building image: $fullImageRef"

    docker build -t $fullImageRef $repoRoot
    if ($LASTEXITCODE -ne 0) { Write-Failure "Docker build failed."; exit 1 }
    Write-Success "Image built: $fullImageRef"

    Write-Step "Docker Push"
    Write-Status "Pushing image to ACR..."

    docker push $fullImageRef
    if ($LASTEXITCODE -ne 0) { Write-Failure "Docker push failed."; exit 1 }
    Write-Success "Image pushed: $fullImageRef"
}

# ── Update Web App Container Settings ───────────────────────────────────────

Write-Step "Updating Web App Container"

Write-Status "Setting container image to: $fullImageRef"

az webapp config container set `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --container-image-name $fullImageRef `
    --container-registry-url "https://$acrLoginServer"
if ($LASTEXITCODE -ne 0) { Write-Failure "Failed to update Web App container settings."; exit 1 }
Write-Success "Web App container settings updated"

# ── Restart & Wait for Deployment ───────────────────────────────────────────

Write-Step "Restarting Web App"

az webapp restart --resource-group $ResourceGroupName --name $WebAppName
if ($LASTEXITCODE -ne 0) { Write-Failure "Failed to restart Web App."; exit 1 }
Write-Status "Restart issued. Waiting for deployment to stabilize..."

# Resolve the Web App URL if not set from terraform
if (-not $webAppUrl) {
    $webAppUrl = az webapp show `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --query "defaultHostName" -o tsv 2>$null
}

if (-not $webAppUrl) {
    Write-Failure "Could not determine Web App URL."
    exit 1
}

# Ensure URL has scheme
if ($webAppUrl -notmatch '^https?://') {
    $webAppUrl = "https://$webAppUrl"
}

$maxRetries = 12
$retryDelay = 10
$healthy = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    Start-Sleep -Seconds $retryDelay
    Write-Status "Health check attempt $i/$maxRetries — $webAppUrl/openapi.json"

    try {
        $response = Invoke-WebRequest -Uri "$webAppUrl/openapi.json" -Method GET -UseBasicParsing -TimeoutSec 15
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    }
    catch {
        Write-Status "Not ready yet ($(($_.Exception.Message -split "`n")[0]))"
    }
}

if ($healthy) {
    Write-Success "Web App is healthy and responding at $webAppUrl"
}
else {
    Write-Failure "Web App did not respond after $maxRetries attempts. Check Azure portal logs."
    exit 1
}

# ── Summary ─────────────────────────────────────────────────────────────────

Write-Step "Deployment Summary"

$summary = @(
    [PSCustomObject]@{ Property = "Image";          Value = $fullImageRef }
    [PSCustomObject]@{ Property = "Web App";         Value = $WebAppName }
    [PSCustomObject]@{ Property = "Resource Group";  Value = $ResourceGroupName }
    [PSCustomObject]@{ Property = "URL";             Value = $webAppUrl }
    [PSCustomObject]@{ Property = "Status";          Value = "Healthy" }
)

$summary | Format-Table -AutoSize

Write-Success "deploy-app.ps1 completed."
