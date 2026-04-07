<#
.SYNOPSIS
    End-to-end deployment: Infrastructure + OIDC + GitHub config + App.

.DESCRIPTION
    One-click script that orchestrates the full veta-agents deployment lifecycle:
      Phase 1 — Azure authentication
      Phase 2 — Terraform infrastructure deployment (AVM modules)
      Phase 3 — OIDC app registration for GitHub Actions
      Phase 4 — GitHub repository variables/secrets configuration
      Phase 5 — Docker build, ACR push, Web App update
      Phase 6 — Summary report

    Each phase can be skipped independently via -Skip* switches.
    The script is idempotent — safe to run multiple times.

.PARAMETER SubscriptionId
    Azure subscription ID (GUID).

.PARAMETER TenantId
    Azure AD tenant ID (GUID).

.PARAMETER GitHubRepo
    GitHub repository in owner/repo format (e.g., Veta-agentic/veta-agents).

.PARAMETER SkipInfra
    Skip Terraform infrastructure deployment.

.PARAMETER SkipApp
    Skip Docker build/push and Web App update.

.PARAMETER SkipOidc
    Skip OIDC app registration and role assignments.

.PARAMETER SkipGitHub
    Skip GitHub variable/secret configuration.

.PARAMETER PlanOnly
    Run Terraform plan without applying.

.PARAMETER ImageTag
    Docker image tag. Default: latest.

.EXAMPLE
    # Full deployment — everything
    .\deploy-all.ps1

.EXAMPLE
    # Infrastructure only, plan first
    .\deploy-all.ps1 -SkipOidc -SkipGitHub -SkipApp -PlanOnly

.EXAMPLE
    # Re-run just OIDC + GitHub config after infra is deployed
    .\deploy-all.ps1 -SkipInfra -SkipApp

.EXAMPLE
    # Deploy app only (infra and OIDC already done)
    .\deploy-all.ps1 -SkipInfra -SkipOidc -SkipGitHub
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$SubscriptionId = "0680501b-ff10-40d8-b73a-4b6fbe760883",

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$TenantId = "5bd20065-3bf3-4766-a65c-efb7fe403ef7",

    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo = "Veta-agentic/veta-agents",

    [switch]$SkipInfra,
    [switch]$SkipApp,
    [switch]$SkipOidc,
    [switch]$SkipGitHub,
    [switch]$PlanOnly,

    [Parameter(Mandatory = $false)]
    [string]$ImageTag = "latest"
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

function Assert-ExitCode {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        Write-Failure $Message
        throw $Message
    }
}

# ── Resolve paths ───────────────────────────────────────────────────────────

$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = Split-Path $PSScriptRoot -Parent }
$tfDir = Join-Path $repoRoot "iac" "TF"

# App registration name
$appDisplayName = "github-veta-agents"

# Track state for summary
$script:deployedOutputs = $null
$script:oidcClientId    = $null
$script:ghVarsSet       = @()
$script:phasesRun       = @()
$script:phasesSkipped   = @()

###############################################################################
# Prerequisites
###############################################################################

Write-Step "Checking Prerequisites"

$azOk = Test-Command "az" "https://learn.microsoft.com/cli/azure/install-azure-cli"

$needTf     = -not $SkipInfra
$needDocker = -not $SkipApp
$needGh     = -not $SkipGitHub

if ($needTf)     { $tfOk     = Test-Command "terraform" "https://developer.hashicorp.com/terraform/install" } else { $tfOk = $true }
if ($needDocker) { $dockerOk = Test-Command "docker"    "https://docs.docker.com/get-docker/" }             else { $dockerOk = $true }
if ($needGh)     { $ghOk     = Test-Command "gh"        "https://cli.github.com/" }                         else { $ghOk = $true }

if (-not $azOk -or -not $tfOk -or -not $dockerOk -or -not $ghOk) {
    Write-Failure "Missing required tools. Install them and retry."
    exit 1
}

###############################################################################
# Phase 1 — Azure Authentication
###############################################################################

Write-Step "Phase 1: Azure Authentication"

try {
    $loggedIn = $false
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($account -and $account.tenantId -eq $TenantId) {
            Write-Success "Already logged in as $($account.user.name) (tenant: $TenantId)"
            $loggedIn = $true
        }
    }
    catch { }

    if (-not $loggedIn) {
        Write-Status "Logging in to Azure tenant $TenantId ..."
        az login --tenant $TenantId
        Assert-ExitCode "Azure login failed."
        Write-Success "Azure login successful"
    }

    Write-Status "Setting subscription to $SubscriptionId ..."
    az account set --subscription $SubscriptionId
    Assert-ExitCode "Failed to set subscription."
    Write-Success "Subscription set"
    $script:phasesRun += "Azure Auth"
}
catch {
    Write-Failure "Phase 1 failed: $_"
    Write-Status "Fix Azure authentication and re-run the script."
    exit 1
}

###############################################################################
# Phase 2 — Infrastructure Deployment
###############################################################################

if ($SkipInfra) {
    Write-Step "Phase 2: Infrastructure Deployment [SKIPPED]"
    $script:phasesSkipped += "Infrastructure"

    # Try to read existing Terraform outputs
    if (Test-Path $tfDir) {
        Write-Status "Reading existing Terraform outputs..."
        Push-Location $tfDir
        try {
            $tfOutputJson = terraform output -json 2>$null
            if ($LASTEXITCODE -eq 0 -and $tfOutputJson) {
                $script:deployedOutputs = $tfOutputJson | ConvertFrom-Json
                Write-Success "Terraform outputs loaded from existing state"
            }
            else {
                Write-Status "No Terraform outputs found — some later phases may need manual values."
            }
        }
        finally {
            Pop-Location
        }
    }
}
else {
    Write-Step "Phase 2: Infrastructure Deployment"

    try {
        if (-not (Test-Path $tfDir)) {
            throw "Terraform directory not found at: $tfDir"
        }

        # Branch-based environment detection
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { $branch = "unknown" }

        if ($branch -eq "main") {
            $environment = "prod"
            $selectedTfvars = "terraform.prod.tfvars"
        }
        else {
            $environment = "dev"
            $selectedTfvars = "terraform.dev.tfvars"
        }

        Write-Status "Branch: $branch → environment: $environment"
        Write-Status "Using tfvars: $selectedTfvars"

        Push-Location $tfDir

        try {
            $tfvarsPath = Join-Path $tfDir $selectedTfvars
            if (-not (Test-Path $tfvarsPath)) {
                throw "tfvars file not found: $tfvarsPath"
            }

            # Terraform Init
            Write-Status "Running terraform init..."
            terraform init -upgrade
            Assert-ExitCode "terraform init failed."
            Write-Success "Terraform initialized"

            # Terraform Plan
            Write-Status "Running terraform plan..."
            $planArgs = @("-var-file=$tfvarsPath", "-var=subscription_id=$SubscriptionId", "-out=tfplan")
            terraform plan @planArgs
            Assert-ExitCode "terraform plan failed."
            Write-Success "Plan saved to tfplan"

            if ($PlanOnly) {
                Write-Status "PlanOnly mode — skipping apply."
                $script:phasesRun += "Infrastructure (plan only)"
            }
            else {
                # Terraform Apply
                Write-Status "Running terraform apply..."
                terraform apply tfplan
                Assert-ExitCode "terraform apply failed."
                Write-Success "Infrastructure deployed"

                # Capture outputs
                $tfOutputJson = terraform output -json
                Assert-ExitCode "Failed to read terraform outputs."
                $script:deployedOutputs = $tfOutputJson | ConvertFrom-Json
                Write-Success "Terraform outputs captured"
                $script:phasesRun += "Infrastructure"
            }
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Write-Failure "Phase 2 failed: $_"
        Write-Status "You can re-run with -SkipInfra to skip this phase if infra is already deployed."
        exit 1
    }
}

# Extract values from Terraform outputs (if available)
$resourceGroupName  = $null
$webAppName         = $null
$acrName            = $null
$webAppHostname     = $null
$keyVaultName       = $null
$cognitiveEndpoint  = $null
$acrResourceId      = $null

if ($script:deployedOutputs) {
    $resourceGroupName = $script:deployedOutputs.resource_group_name.value
    $webAppName        = $script:deployedOutputs.web_app_name.value
    $acrName           = $script:deployedOutputs.container_registry_name.value
    $webAppHostname    = $script:deployedOutputs.web_app_default_hostname.value
    $keyVaultName      = $script:deployedOutputs.key_vault_name.value
    $cognitiveEndpoint = $script:deployedOutputs.cognitive_account_endpoint.value
    $acrResourceId     = $script:deployedOutputs.container_registry_id.value

    Write-Status "Resource Group : $resourceGroupName"
    Write-Status "Web App        : $webAppName"
    Write-Status "ACR            : $acrName"
    Write-Status "Key Vault      : $keyVaultName"
}

###############################################################################
# Phase 3 — OIDC App Registration
###############################################################################

if ($SkipOidc) {
    Write-Step "Phase 3: OIDC App Registration [SKIPPED]"
    $script:phasesSkipped += "OIDC"
}
else {
    Write-Step "Phase 3: OIDC App Registration"

    try {
        # Check if app registration already exists
        Write-Status "Checking for existing app registration '$appDisplayName'..."
        $appJson = az ad app list --display-name $appDisplayName --query "[0]" -o json 2>$null
        if ($appJson -and $appJson -ne "null") {
            $app = $appJson | ConvertFrom-Json
            Write-Success "App registration already exists: $($app.appId)"
        }
        else {
            Write-Status "Creating app registration '$appDisplayName'..."
            $appJson = az ad app create --display-name $appDisplayName -o json
            Assert-ExitCode "Failed to create app registration."
            $app = $appJson | ConvertFrom-Json
            Write-Success "App registration created: $($app.appId)"
        }

        $clientId = $app.appId
        $appObjectId = $app.id
        $script:oidcClientId = $clientId

        # Create service principal if not exists
        Write-Status "Ensuring service principal exists..."
        $existingSp = az ad sp list --filter "appId eq '$clientId'" --query "[0].id" -o tsv 2>$null
        if ($existingSp) {
            Write-Success "Service principal already exists"
        }
        else {
            az ad sp create --id $clientId -o none
            Assert-ExitCode "Failed to create service principal."
            Write-Success "Service principal created"
        }

        # Federated credential for main branch
        Write-Status "Checking federated credential for main branch..."
        $existingCreds = az ad app federated-credential list --id $appObjectId -o json 2>$null | ConvertFrom-Json
        $mainCredExists = $existingCreds | Where-Object { $_.name -eq "github-main-branch" }
        if ($mainCredExists) {
            Write-Success "Federated credential 'github-main-branch' already exists"
        }
        else {
            Write-Status "Creating federated credential for main branch..."
            $mainCredParams = @{
                name      = "github-main-branch"
                issuer    = "https://token.actions.githubusercontent.com"
                subject   = "repo:${GitHubRepo}:ref:refs/heads/main"
                audiences = @("api://AzureADTokenExchange")
            } | ConvertTo-Json -Depth 5
            $mainCredFile = [System.IO.Path]::GetTempFileName()
            $mainCredParams | Out-File -FilePath $mainCredFile -Encoding utf8
            az ad app federated-credential create --id $appObjectId --parameters "@$mainCredFile" -o none
            $credExitCode = $LASTEXITCODE
            Remove-Item $mainCredFile -ErrorAction SilentlyContinue
            if ($credExitCode -ne 0) { throw "Failed to create main branch federated credential." }
            Write-Success "Federated credential created for main branch"
        }

        # Federated credential for pull requests
        Write-Status "Checking federated credential for pull requests..."
        $prCredExists = $existingCreds | Where-Object { $_.name -eq "github-pull-requests" }
        if ($prCredExists) {
            Write-Success "Federated credential 'github-pull-requests' already exists"
        }
        else {
            Write-Status "Creating federated credential for pull requests..."
            $prCredParams = @{
                name      = "github-pull-requests"
                issuer    = "https://token.actions.githubusercontent.com"
                subject   = "repo:${GitHubRepo}:pull_request"
                audiences = @("api://AzureADTokenExchange")
            } | ConvertTo-Json -Depth 5
            $prCredFile = [System.IO.Path]::GetTempFileName()
            $prCredParams | Out-File -FilePath $prCredFile -Encoding utf8
            az ad app federated-credential create --id $appObjectId --parameters "@$prCredFile" -o none
            $credExitCode = $LASTEXITCODE
            Remove-Item $prCredFile -ErrorAction SilentlyContinue
            if ($credExitCode -ne 0) { throw "Failed to create pull request federated credential." }
            Write-Success "Federated credential created for pull requests"
        }

        # Assign Contributor on subscription
        Write-Status "Checking Contributor role assignment on subscription..."
        $subScope = "/subscriptions/$SubscriptionId"
        $existingContrib = az role assignment list `
            --assignee $clientId `
            --role "Contributor" `
            --scope $subScope `
            --query "[0].id" -o tsv 2>$null
        if ($existingContrib) {
            Write-Success "Contributor role already assigned"
        }
        else {
            Write-Status "Assigning Contributor role on subscription..."
            az role assignment create --assignee $clientId --role "Contributor" --scope $subScope -o none
            Assert-ExitCode "Failed to assign Contributor role."
            Write-Success "Contributor role assigned"
        }

        # Assign AcrPush on ACR (if ACR resource ID is available)
        if ($acrResourceId) {
            Write-Status "Checking AcrPush role assignment on ACR..."
            $existingAcrPush = az role assignment list `
                --assignee $clientId `
                --role "AcrPush" `
                --scope $acrResourceId `
                --query "[0].id" -o tsv 2>$null
            if ($existingAcrPush) {
                Write-Success "AcrPush role already assigned on ACR"
            }
            else {
                Write-Status "Assigning AcrPush role on ACR..."
                az role assignment create --assignee $clientId --role "AcrPush" --scope $acrResourceId -o none
                Assert-ExitCode "Failed to assign AcrPush role."
                Write-Success "AcrPush role assigned on ACR"
            }
        }
        else {
            Write-Status "ACR resource ID not available — skipping AcrPush role assignment."
            Write-Status "Run without -SkipInfra first, or assign manually."
        }

        $script:phasesRun += "OIDC"
    }
    catch {
        Write-Failure "Phase 3 failed: $_"
        Write-Status "You can re-run with -SkipOidc to skip this phase."
        exit 1
    }
}

###############################################################################
# Phase 4 — GitHub Variables/Secrets
###############################################################################

if ($SkipGitHub) {
    Write-Step "Phase 4: GitHub Variables [SKIPPED]"
    $script:phasesSkipped += "GitHub"
}
else {
    Write-Step "Phase 4: GitHub Variables"

    try {
        # Verify gh CLI is authenticated
        Write-Status "Verifying GitHub CLI authentication..."
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Failure "GitHub CLI is not authenticated. Run 'gh auth login' first."
            throw "GitHub CLI not authenticated"
        }
        Write-Success "GitHub CLI authenticated"

        # Resolve OIDC client ID — from Phase 3 or existing registration
        $ghClientId = $script:oidcClientId
        if (-not $ghClientId) {
            Write-Status "Looking up existing app registration for client ID..."
            $ghClientId = az ad app list --display-name $appDisplayName --query "[0].appId" -o tsv 2>$null
        }

        # Build variable map
        $variables = [ordered]@{}

        if ($ghClientId) {
            $variables["AZURE_CLIENT_ID"] = $ghClientId
        }
        else {
            Write-Status "AZURE_CLIENT_ID not available — run without -SkipOidc to create it."
        }

        $variables["AZURE_TENANT_ID"]       = $TenantId
        $variables["AZURE_SUBSCRIPTION_ID"] = $SubscriptionId

        if ($acrName)           { $variables["ACR_NAME"]       = $acrName }
        if ($webAppName)        { $variables["WEB_APP_NAME"]   = $webAppName }
        if ($resourceGroupName) { $variables["RESOURCE_GROUP"] = $resourceGroupName }

        if ($webAppHostname) {
            $httpUrl = $webAppHostname
            if ($httpUrl -notlike "https://*" -and $httpUrl -notlike "http://*") { $httpUrl = "https://$httpUrl" }
            $variables["HTTP_URL"] = "$httpUrl/ask"
        }

        # Set each variable
        foreach ($kv in $variables.GetEnumerator()) {
            Write-Status "Setting $($kv.Key) ..."
            gh variable set $kv.Key -R $GitHubRepo --body $kv.Value
            Assert-ExitCode "Failed to set GitHub variable $($kv.Key)."
            $script:ghVarsSet += $kv.Key
        }

        Write-Success "$($variables.Count) GitHub variables configured"
        $script:phasesRun += "GitHub"
    }
    catch {
        Write-Failure "Phase 4 failed: $_"
        Write-Status "You can re-run with -SkipGitHub to skip this phase."
        exit 1
    }
}

###############################################################################
# Phase 5 — App Deployment
###############################################################################

if ($SkipApp) {
    Write-Step "Phase 5: App Deployment [SKIPPED]"
    $script:phasesSkipped += "App Deploy"
}
else {
    Write-Step "Phase 5: App Deployment"

    try {
        if (-not $acrName -or -not $webAppName -or -not $resourceGroupName) {
            throw "Missing resource names. Run without -SkipInfra first, or provide them via Terraform outputs."
        }

        $acrLoginServer = "$acrName.azurecr.io"
        $imageName      = "veta-agents"
        $fullImageRef   = "${acrLoginServer}/${imageName}:${ImageTag}"

        # ACR Login
        Write-Status "Logging in to ACR: $acrName ..."
        az acr login --name $acrName
        Assert-ExitCode "ACR login failed."
        Write-Success "ACR login successful"

        # Docker Build
        Write-Status "Building image: $fullImageRef"
        docker build -t $fullImageRef $repoRoot
        Assert-ExitCode "Docker build failed."
        Write-Success "Image built"

        # Docker Push
        Write-Status "Pushing image to ACR..."
        docker push $fullImageRef
        Assert-ExitCode "Docker push failed."
        Write-Success "Image pushed"

        # Update Web App
        Write-Status "Updating Web App container settings..."
        az webapp config container set `
            --resource-group $resourceGroupName `
            --name $webAppName `
            --container-image-name $fullImageRef `
            --container-registry-url "https://$acrLoginServer"
        Assert-ExitCode "Failed to update Web App container settings."
        Write-Success "Web App container updated"

        # Restart
        Write-Status "Restarting Web App..."
        az webapp restart --resource-group $resourceGroupName --name $webAppName
        Assert-ExitCode "Failed to restart Web App."

        # Health check
        $healthUrl = $webAppHostname
        if ($healthUrl -and $healthUrl -notlike "https://*" -and $healthUrl -notlike "http://*") { $healthUrl = "https://$healthUrl" }

        if ($healthUrl) {
            Write-Status "Waiting for Web App to respond..."
            $maxRetries = 12
            $retryDelay = 10
            $healthy = $false

            for ($i = 1; $i -le $maxRetries; $i++) {
                Start-Sleep -Seconds $retryDelay
                Write-Status "Health check attempt $i/$maxRetries — $healthUrl/openapi.json"
                try {
                    $response = Invoke-WebRequest -Uri "$healthUrl/openapi.json" -Method GET -UseBasicParsing -TimeoutSec 15
                    if ($response.StatusCode -eq 200) {
                        $healthy = $true
                        break
                    }
                }
                catch {
                    Write-Status "Not ready yet..."
                }
            }

            if ($healthy) {
                Write-Success "Web App is healthy"
            }
            else {
                Write-Failure "Web App did not respond after $maxRetries attempts. Check Azure portal logs."
            }
        }

        $script:phasesRun += "App Deploy"
    }
    catch {
        Write-Failure "Phase 5 failed: $_"
        Write-Status "You can re-run with -SkipApp to skip this phase."
        exit 1
    }
}

###############################################################################
# Phase 6 — Summary
###############################################################################

Write-Step "Phase 6: Deployment Summary"

# Phases
Write-Host ""
Write-Host "  Phases completed : " -NoNewline -ForegroundColor White
Write-Host ($script:phasesRun -join ", ") -ForegroundColor Green
if ($script:phasesSkipped.Count -gt 0) {
    Write-Host "  Phases skipped   : " -NoNewline -ForegroundColor White
    Write-Host ($script:phasesSkipped -join ", ") -ForegroundColor DarkGray
}

# Resources
if ($script:deployedOutputs) {
    Write-Host ""
    Write-Host "  Azure Resources:" -ForegroundColor White
    $resourceTable = @(
        [PSCustomObject]@{ Resource = "Resource Group";     Value = $resourceGroupName }
        [PSCustomObject]@{ Resource = "Web App";            Value = $webAppName }
        [PSCustomObject]@{ Resource = "Container Registry"; Value = $acrName }
        [PSCustomObject]@{ Resource = "Key Vault";          Value = $keyVaultName }
        [PSCustomObject]@{ Resource = "Cognitive Endpoint"; Value = $cognitiveEndpoint }
    )
    $resourceTable | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "  $_" }
}

# URLs
if ($webAppHostname) {
    $baseUrl = $webAppHostname
    if ($baseUrl -notlike "https://*" -and $baseUrl -notlike "http://*") { $baseUrl = "https://$baseUrl" }
    Write-Host "  URLs:" -ForegroundColor White
    Write-Host "    Web App     : $baseUrl" -ForegroundColor Cyan
    Write-Host "    OpenAPI     : $baseUrl/openapi.json" -ForegroundColor Cyan
    Write-Host "    Ask endpoint: $baseUrl/ask" -ForegroundColor Cyan
}

# OIDC
if ($script:oidcClientId) {
    Write-Host ""
    Write-Host "  OIDC App Registration:" -ForegroundColor White
    Write-Host "    App Name  : $appDisplayName" -ForegroundColor Cyan
    Write-Host "    Client ID : $script:oidcClientId" -ForegroundColor Cyan
    Write-Host "    Federated : main branch + pull requests" -ForegroundColor Cyan
}

# GitHub Variables
if ($script:ghVarsSet.Count -gt 0) {
    Write-Host ""
    Write-Host "  GitHub Variables Set ($GitHubRepo):" -ForegroundColor White
    foreach ($v in $script:ghVarsSet) {
        Write-Host "    ✓ $v" -ForegroundColor Green
    }
}

# Manual steps
Write-Host ""
Write-Host "  ⚠ Pending Manual Steps:" -ForegroundColor Yellow
Write-Host "    • Set GitHub secret HTTP_API_KEY with your API key value" -ForegroundColor Yellow
Write-Host "      gh secret set HTTP_API_KEY -R $GitHubRepo" -ForegroundColor DarkGray
if (-not $script:oidcClientId -and $SkipOidc) {
    Write-Host "    • Create OIDC app registration (re-run without -SkipOidc)" -ForegroundColor Yellow
}
if (-not $script:deployedOutputs -and $SkipInfra) {
    Write-Host "    • Deploy infrastructure (re-run without -SkipInfra)" -ForegroundColor Yellow
}

Write-Host ""
Write-Success "deploy-all.ps1 completed."
