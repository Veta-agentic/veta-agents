# filepath: d:\gitrepos\personal\veta-agents\scripts\pre-requirements.ps1

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

function Test-UvInstalled {
    try {
        $null = Get-Command uv -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "uv is not installed. Please go to https://docs.astral.sh/uv/getting-started/installation/." -ForegroundColor Red
        return $false
    }
}

function Test-DockerInstalled {
    try {
        $null = Get-Command docker -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "docker is not installed. Please go to https://docs.docker.com/get-docker/." -ForegroundColor Red
        return $false
    }
}

# Check requirements
$uvInstalled = Test-UvInstalled
$dockerInstalled = Test-DockerInstalled

if (-not $uvInstalled -or -not $dockerInstalled) {
    Write-Host "One or more required tools are missing. Please install them before proceeding." -ForegroundColor Red
    exit 1
}

Write-Host "All required tools are installed!" -ForegroundColor Green