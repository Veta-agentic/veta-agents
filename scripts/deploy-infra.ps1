<#
.SYNOPSIS
    Deploys the Terraform infrastructure for the GitHub AI Bot (veta-agents).

.DESCRIPTION
    Provisions all Azure resources using Terraform with AVM modules:
    Resource Group, Key Vault, App Service Plan, Web App, Log Analytics,
    Application Insights, Cognitive Services (OpenAI), Storage Account,
    and Container Registry.

    Automatically selects the environment based on the current git branch:
      - main branch  → prod  → terraform.prod.tfvars
      - other branch → dev   → terraform.dev.tfvars

    Use -TfVarsFile to override the auto-detected tfvars file.
    If -SubscriptionId is provided it overrides the value in the tfvars file.

.PARAMETER SubscriptionId
    Azure subscription ID (GUID). Used for Azure login and, when provided,
    overrides the subscription_id in the selected tfvars file.

.PARAMETER TenantId
    Azure AD tenant ID (GUID) for authentication.

.PARAMETER TfVarsFile
    Optional path to a custom tfvars file. Overrides branch-based detection.

.PARAMETER PlanOnly
    If set, runs terraform plan but does NOT apply.

.EXAMPLE
    # Auto-detect environment from branch (dev or prod)
    .\deploy-infra.ps1 -SubscriptionId "00000000-..." -TenantId "00000000-..."

.EXAMPLE
    # Plan only — preview changes without applying
    .\deploy-infra.ps1 -SubscriptionId "00000000-..." -TenantId "00000000-..." -PlanOnly

.EXAMPLE
    # Use a custom tfvars file
    .\deploy-infra.ps1 -SubscriptionId "00000000-..." -TenantId "00000000-..." -TfVarsFile "./my-custom.tfvars"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$')]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$TfVarsFile,

    [Parameter(Mandatory = $false)]
    [switch]$PlanOnly
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

$tfOk = Test-Command "terraform" "https://developer.hashicorp.com/terraform/install"
$azOk = Test-Command "az"        "https://learn.microsoft.com/cli/azure/install-azure-cli"

if (-not $tfOk -or -not $azOk) {
    Write-Failure "Missing required tools. Install them and retry."
    exit 1
}

# ── Branch Detection & Environment Selection ────────────────────────────────

Write-Step "Detecting Environment from Git Branch"

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $branch) { $branch = "unknown" }

if ($branch -eq "main") {
    $Environment = "prod"
    $defaultTfvars = "terraform.prod.tfvars"
} else {
    $Environment = "dev"
    $defaultTfvars = "terraform.dev.tfvars"
}

if ($TfVarsFile) {
    $selectedTfvars = $TfVarsFile
    Write-Status "Branch: $branch → environment: $Environment (tfvars overridden)"
    Write-Status "Using custom tfvars: $selectedTfvars"
} else {
    $selectedTfvars = $defaultTfvars
    Write-Status "Branch: $branch → environment: $Environment"
    Write-Status "Using tfvars: $selectedTfvars"
}

# ── Azure Login ─────────────────────────────────────────────────────────────

Write-Step "Azure Authentication"

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
    if ($LASTEXITCODE -ne 0) { Write-Failure "Azure login failed."; exit 1 }
    Write-Success "Azure login successful"
}

Write-Status "Setting subscription to $SubscriptionId ..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { Write-Failure "Failed to set subscription."; exit 1 }
Write-Success "Subscription set"

# ── Navigate to Terraform directory ─────────────────────────────────────────

$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = Split-Path $PSScriptRoot -Parent }
$tfDir = Join-Path $repoRoot "iac" "TF"

if (-not (Test-Path $tfDir)) {
    Write-Failure "Terraform directory not found at: $tfDir"
    exit 1
}

Write-Status "Working in: $tfDir"
Push-Location $tfDir

try {
    # ── Validate tfvars file ───────────────────────────────────────────────

    $tfvarsPath = Join-Path $tfDir $selectedTfvars
    if (-not (Test-Path $tfvarsPath)) {
        # If a custom path was given, try it as-is (absolute or relative to cwd)
        if ($TfVarsFile -and (Test-Path $TfVarsFile)) {
            $tfvarsPath = $TfVarsFile
        } else {
            Write-Failure "tfvars file not found: $tfvarsPath"
            exit 1
        }
    }
    Write-Success "tfvars file found: $tfvarsPath"

    # ── Terraform Init ──────────────────────────────────────────────────────

    Write-Step "Terraform Init"

    terraform init -upgrade
    if ($LASTEXITCODE -ne 0) { Write-Failure "terraform init failed."; exit 1 }
    Write-Success "Terraform initialized"

    # ── Terraform Plan ──────────────────────────────────────────────────────

    Write-Step "Terraform Plan"

    $planArgs = @("-var-file=$tfvarsPath", "-out=tfplan")
    if ($SubscriptionId) {
        $planArgs += "-var=subscription_id=$SubscriptionId"
    }

    terraform plan @planArgs
    if ($LASTEXITCODE -ne 0) { Write-Failure "terraform plan failed."; exit 1 }
    Write-Success "Plan saved to tfplan"

    # ── Terraform Apply ─────────────────────────────────────────────────────

    if ($PlanOnly) {
        Write-Status "PlanOnly mode — skipping apply."
    }
    else {
        Write-Step "Terraform Apply"

        terraform apply tfplan
        if ($LASTEXITCODE -ne 0) { Write-Failure "terraform apply failed."; exit 1 }
        Write-Success "Infrastructure deployed successfully"

        # ── Output key values ───────────────────────────────────────────────

        Write-Step "Deployment Outputs"

        $outputs = terraform output -json | ConvertFrom-Json

        $outputTable = @(
            [PSCustomObject]@{ Resource = "Resource Group";     Value = $outputs.resource_group_name.value }
            [PSCustomObject]@{ Resource = "Web App Name";       Value = $outputs.web_app_name.value }
            [PSCustomObject]@{ Resource = "Web App URL";        Value = $outputs.web_app_default_hostname.value }
            [PSCustomObject]@{ Resource = "ACR Name";           Value = $outputs.container_registry_name.value }
            [PSCustomObject]@{ Resource = "Key Vault Name";     Value = $outputs.key_vault_name.value }
            [PSCustomObject]@{ Resource = "Key Vault URI";      Value = $outputs.key_vault_uri.value }
            [PSCustomObject]@{ Resource = "App Insights ID";    Value = $outputs.app_insights_id.value }
            [PSCustomObject]@{ Resource = "Storage Account";    Value = $outputs.storage_account_name.value }
            [PSCustomObject]@{ Resource = "Cognitive Endpoint"; Value = $outputs.cognitive_account_endpoint.value }
        )

        $outputTable | Format-Table -AutoSize

        Write-Success "All outputs retrieved. Use 'terraform output' for full details."
    }
}
finally {
    Pop-Location
}

Write-Host "`n" -NoNewline
Write-Success "deploy-infra.ps1 completed."
