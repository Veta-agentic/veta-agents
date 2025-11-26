# filepath: d:\gitrepos\personal\veta-agents\scripts\local-setup.ps1

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

function Main {
    Install-GitHooks
}

function Install-GitHooks {
    Write-Host "Installing git hooks..." -ForegroundColor Green
    git config core.hooksPath scripts/hooks
    Write-Host "Git hooks installed successfully!" -ForegroundColor Green
}

# Execute main function
Main