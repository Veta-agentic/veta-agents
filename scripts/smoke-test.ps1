<#
.SYNOPSIS
    Smoke-tests the deployed veta-agents infrastructure and application.

.DESCRIPTION
    Validates that all Azure resources exist, are properly configured,
    and that the web application responds correctly. Produces a summary
    table with pass/fail status per check.

.PARAMETER WebAppUrl
    Full URL of the Web App (e.g., https://app-ghbot-123.azurewebsites.net).

.PARAMETER ResourceGroupName
    Azure Resource Group name. Used to auto-discover the Web App URL and verify resources.

.PARAMETER WebAppName
    Azure Web App name. Used with ResourceGroupName to auto-discover the URL.

.PARAMETER SubscriptionId
    Azure subscription ID for resource verification. Auto-detected if omitted.

.EXAMPLE
    .\smoke-test.ps1 -WebAppUrl "https://app-ghbot-123.azurewebsites.net" -ResourceGroupName "rsg-ghbot-123"

.EXAMPLE
    .\smoke-test.ps1 -ResourceGroupName "rsg-ghbot-123" -WebAppName "app-ghbot-123"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WebAppUrl,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$WebAppName,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

$ErrorActionPreference = "Stop"

# ── Helper functions ────────────────────────────────────────────────────────

function Write-Status  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Failure { param([string]$Message) Write-Host "[FAIL]  $Message" -ForegroundColor Red }
function Write-Step    { param([string]$Message) Write-Host "`n═══ $Message ═══" -ForegroundColor Yellow }

# Results collector
$script:results = [System.Collections.ArrayList]::new()

function Add-Result {
    param(
        [string]$Category,
        [string]$Check,
        [bool]$Passed,
        [string]$Details = ""
    )
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $null = $script:results.Add([PSCustomObject]@{
        Category = $Category
        Check    = $Check
        Status   = $status
        Details  = $Details
    })
    if ($Passed) { Write-Success "$Check" } else { Write-Failure "$Check — $Details" }
}

function Test-AzResource {
    param(
        [string]$ResourceType,
        [string]$ResourceGroup,
        [string]$DisplayName
    )
    $resources = az resource list `
        --resource-group $ResourceGroup `
        --resource-type $ResourceType `
        --query "[].name" -o tsv 2>$null

    if ($LASTEXITCODE -eq 0 -and $resources) {
        $names = ($resources -split "`n" | ForEach-Object { $_.Trim() }) -join ", "
        Add-Result "Infrastructure" $DisplayName $true $names
        return $true
    }
    else {
        Add-Result "Infrastructure" $DisplayName $false "Not found in $ResourceGroup"
        return $false
    }
}

# ── Parameter Validation ────────────────────────────────────────────────────

if (-not $WebAppUrl -and -not ($ResourceGroupName -and $WebAppName)) {
    Write-Failure "Provide either -WebAppUrl or both -ResourceGroupName and -WebAppName."
    exit 1
}

if (-not $ResourceGroupName) {
    Write-Failure "ResourceGroupName is required for infrastructure checks."
    exit 1
}

# ── Auto-discover Web App URL ───────────────────────────────────────────────

Write-Step "Initializing"

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId 2>$null
}

if (-not $WebAppUrl -and $WebAppName) {
    Write-Status "Discovering Web App URL..."
    $hostname = az webapp show `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --query "defaultHostName" -o tsv 2>$null

    if ($hostname) {
        $WebAppUrl = "https://$hostname"
        Write-Success "Discovered URL: $WebAppUrl"
    }
    else {
        Write-Failure "Could not discover Web App URL."
    }
}

# Ensure URL has scheme
if ($WebAppUrl -and $WebAppUrl -notmatch '^https?://') {
    $WebAppUrl = "https://$WebAppUrl"
}

###############################################################################
# Infrastructure Checks
###############################################################################

Write-Step "Infrastructure Verification"

# Verify Resource Group exists
$rgExists = az group show --name $ResourceGroupName --query "name" -o tsv 2>$null
if ($rgExists) {
    Add-Result "Infrastructure" "Resource Group exists" $true $ResourceGroupName
}
else {
    Add-Result "Infrastructure" "Resource Group exists" $false "RG '$ResourceGroupName' not found"
}

# Verify each resource type
Test-AzResource "Microsoft.Web/sites"                      $ResourceGroupName "Web App exists"
Test-AzResource "Microsoft.Web/serverFarms"                $ResourceGroupName "App Service Plan exists"
Test-AzResource "Microsoft.KeyVault/vaults"                $ResourceGroupName "Key Vault exists"
Test-AzResource "Microsoft.ContainerRegistry/registries"   $ResourceGroupName "Container Registry exists"
Test-AzResource "Microsoft.Insights/components"            $ResourceGroupName "App Insights exists"
Test-AzResource "Microsoft.CognitiveServices/accounts"     $ResourceGroupName "Cognitive Services exists"
Test-AzResource "Microsoft.Storage/storageAccounts"        $ResourceGroupName "Storage Account exists"
Test-AzResource "Microsoft.OperationalInsights/workspaces" $ResourceGroupName "Log Analytics exists"

###############################################################################
# Web App Configuration Checks
###############################################################################

Write-Step "Web App Configuration"

if ($WebAppName) {
    # Check Web App is running
    $state = az webapp show `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --query "state" -o tsv 2>$null

    Add-Result "Configuration" "Web App is running" ($state -eq "Running") "State: $state"

    # Check managed identity
    $identity = az webapp identity show `
        --resource-group $ResourceGroupName `
        --name $WebAppName `
        --query "principalId" -o tsv 2>$null

    $hasIdentity = (-not [string]::IsNullOrWhiteSpace($identity))
    Add-Result "Configuration" "Managed identity configured" $hasIdentity $(
        if ($hasIdentity) { "PrincipalId: $($identity.Substring(0,8))..." } else { "No system-assigned identity" }
    )

    # Check RBAC role assignments
    if ($hasIdentity) {
        $roles = az role assignment list `
            --assignee $identity `
            --query "[].roleDefinitionName" -o tsv 2>$null

        $roleList = if ($roles) { ($roles -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } else { @() }

        $expectedRoles = @("Key Vault Secrets User", "AcrPull", "Storage Blob Data Contributor")
        foreach ($role in $expectedRoles) {
            $found = $roleList -contains $role
            Add-Result "RBAC" "Role: $role" $found $(
                if ($found) { "Assigned" } else { "Not found on principal $($identity.Substring(0,8))..." }
            )
        }
    }
    else {
        foreach ($role in @("Key Vault Secrets User", "AcrPull", "Storage Blob Data Contributor")) {
            Add-Result "RBAC" "Role: $role" $false "Skipped — no managed identity"
        }
    }
}

###############################################################################
# Application Endpoint Tests
###############################################################################

Write-Step "Application Endpoint Tests"

if ($WebAppUrl) {
    # Test OpenAPI schema endpoint (no auth required)
    try {
        $response = Invoke-WebRequest -Uri "$WebAppUrl/openapi.json" -Method GET -UseBasicParsing -TimeoutSec 30
        $isOk = ($response.StatusCode -eq 200)
        Add-Result "Application" "GET /openapi.json" $isOk "HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        Add-Result "Application" "GET /openapi.json" $false "HTTP $statusCode — $($_.Exception.Message.Substring(0, [Math]::Min(80, $_.Exception.Message.Length)))"
    }

    # Test POST /ask — expects 403/401 without API key, which proves the endpoint is live
    try {
        $askBody = @{ question = "smoke test"; githubRepo = "test/repo"; githubWikis = @("test") } | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$WebAppUrl/ask" -Method POST -Body $askBody `
            -ContentType "application/json" -UseBasicParsing -TimeoutSec 30
        Add-Result "Application" "POST /ask (responds)" $true "HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        # 401/403 means the endpoint is live but auth is required — that's a pass
        $isAuthError = ($statusCode -eq 401 -or $statusCode -eq 403 -or $statusCode -eq 422)
        Add-Result "Application" "POST /ask (responds)" $isAuthError $(
            if ($isAuthError) { "HTTP $statusCode (auth/validation required — endpoint live)" }
            else { "HTTP $statusCode — unexpected error" }
        )
    }

    # Test POST /fix/exceptions — same auth-gated check
    try {
        $fixBody = @{
            azureLogAnalyticsWorkspaceId = "test-workspace-id"
            githubRepo                   = "test/repo"
        } | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$WebAppUrl/fix/exceptions" -Method POST -Body $fixBody `
            -ContentType "application/json" -UseBasicParsing -TimeoutSec 30
        Add-Result "Application" "POST /fix/exceptions (responds)" $true "HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        $isAuthError = ($statusCode -eq 401 -or $statusCode -eq 403 -or $statusCode -eq 422)
        Add-Result "Application" "POST /fix/exceptions (responds)" $isAuthError $(
            if ($isAuthError) { "HTTP $statusCode (auth/validation required — endpoint live)" }
            else { "HTTP $statusCode — unexpected error" }
        )
    }
}
else {
    Add-Result "Application" "GET /openapi.json" $false "No Web App URL available"
    Add-Result "Application" "POST /ask" $false "No Web App URL available"
    Add-Result "Application" "POST /fix/exceptions" $false "No Web App URL available"
}

###############################################################################
# Summary Report
###############################################################################

Write-Step "Smoke Test Results"

$script:results | Format-Table -Property Category, Check, Status, Details -AutoSize

$totalChecks  = $script:results.Count
$passedChecks = ($script:results | Where-Object { $_.Status -eq "PASS" }).Count
$failedChecks = $totalChecks - $passedChecks

Write-Host ""
if ($failedChecks -eq 0) {
    Write-Success "All $totalChecks checks passed!"
    exit 0
}
else {
    Write-Failure "$failedChecks of $totalChecks checks failed."
    exit 1
}
