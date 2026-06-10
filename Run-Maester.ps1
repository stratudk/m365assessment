#Requires -Version 7

<#
.SYNOPSIS
    Runs Maester against your Microsoft 365 tenant with FULL coverage and saves
    the results to a single JSON file you can send back to your Statu
    consultant.

    Run this on your own machine in PowerShell 7 — a browser window opens for
    sign-in. Azure Cloud Shell is not supported: the full test set needs
    interactive sign-ins (Exchange Online, Teams, Purview, Azure) that Cloud
    Shell's device-code flow cannot complete.

.DESCRIPTION
    No app registration and nothing permanent to install. You sign in with your
    own account; Maester reads your security configuration (READ ONLY — it never
    changes anything) and writes the results to a single .json file.

    What it does, step by step:
      1. Installs the Maester + Pester PowerShell modules (just for your session).
      2. Downloads the latest Maester test set.
      3. Signs you in (a browser window opens) and connects to every service:
         Entra/Graph, Exchange Online, Teams, Purview, Azure and (best-effort)
         Dataverse for the Copilot Studio agent-security tests. Copilot Studio is
         optional — if there's no environment to read it is skipped, not failed.
      4. Runs the full test set and writes maester-results.json.
      5. Tells you where the file is and how to send it to us.

.PARAMETER UseDeviceCode
    Force device-code sign-in (a short code you enter at microsoft.com/devicelogin
    in another tab). Use this only if a browser window can't open on your machine.
    Note: some full-coverage services may not connect via device code, so prefer
    the default browser sign-in whenever possible.

.PARAMETER OutputFile
    Where to write the results. Defaults to maester-results.json in your home
    directory.

.NOTES
    Requirements : PowerShell 7 (run 'pwsh', NOT Windows PowerShell 5.1).
                   On Windows:  winget install Microsoft.PowerShell
                   On macOS:    brew install powershell
    Permissions  : your account needs the Global Reader (or Security Reader) role
                   to read every setting. A normal user account will still run but
                   some tests will be skipped.
    Safe to run  : read-only. No configuration is changed in your tenant.
#>

[CmdletBinding()]
param(
    [switch]$UseDeviceCode,
    [string]$OutputFile = "$HOME/maester-results.json"
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Statu - M365 Reality Check (full coverage)" -ForegroundColor Cyan
Write-Host " Read-only. No app registration. Nothing is changed." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ----------------------------------------------------------------------------
# 1. Install the modules (current user only — no admin rights needed)
# ----------------------------------------------------------------------------
Write-Step "Installing Maester, Pester and the service modules (this can take a few minutes)..."
Install-Module Pester  -SkipPublisherCheck -Force -Scope CurrentUser
Install-Module Maester -Force -Scope CurrentUser

# Service modules required for full coverage. 'Connect-Maester -Service All' uses
# these to reach Exchange Online / Purview (ExchangeOnlineManagement), Teams
# (MicrosoftTeams) and Azure (Az.Accounts). Without them those connections are
# skipped and ~300 tests don't run. Installed for the current user only.
Install-Module ExchangeOnlineManagement -Force -Scope CurrentUser
Install-Module MicrosoftTeams           -Force -Scope CurrentUser
Install-Module Az.Accounts              -Force -Scope CurrentUser

Import-Module Maester

# ----------------------------------------------------------------------------
# 2. Download the latest Maester tests into a working folder
# ----------------------------------------------------------------------------
Write-Step "Downloading the latest Maester tests..."
$workDir = Join-Path $HOME 'maester-tests'
if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir | Out-Null }
Set-Location $workDir

# Install into a fresh folder; refresh in place if tests are already present.
# Install-MaesterTests prompts interactively when the folder isn't empty, which
# would hang an unattended run — Update-MaesterTests -Force refreshes silently.
$haveTests = @(Get-ChildItem -Path $workDir -Recurse -Filter '*.Tests.ps1' -ErrorAction SilentlyContinue).Count -gt 0
if ($haveTests) {
    Update-MaesterTests -Force
} else {
    Install-MaesterTests
}

# ----------------------------------------------------------------------------
# 3. Sign in and connect to every service (full coverage)
# ----------------------------------------------------------------------------
Write-Step "Signing you in and connecting to all services..."

if ($UseDeviceCode) {
    Write-Host "   You'll see a message with a short code. Open" -ForegroundColor Yellow
    Write-Host "   https://microsoft.com/devicelogin in another browser tab," -ForegroundColor Yellow
    Write-Host "   enter the code, and approve the read-only access." -ForegroundColor Yellow
} else {
    Write-Host "   A browser window will open — sign in and approve the" -ForegroundColor Yellow
    Write-Host "   read-only access." -ForegroundColor Yellow
}
Write-Host "   Full coverage: expect several sign-in prompts (Entra/Graph," -ForegroundColor Yellow
Write-Host "   Exchange Online, Teams, Purview, Azure)." -ForegroundColor Yellow
Write-Host "   Copilot Studio (Dataverse) tests are included but optional: if" -ForegroundColor Yellow
Write-Host "   there's no Copilot Studio environment to read, those tests are" -ForegroundColor Yellow
Write-Host "   simply skipped — that's expected and does not stop the run." -ForegroundColor Yellow
Write-Host ""

# Connect to every service so the full test set can run. '-Service All' covers
# Entra/Graph, Exchange Online, Teams, Purview (Security & Compliance), Azure AND
# Dataverse (for the Copilot Studio agent-security tests).
#
# Dataverse/Copilot is best-effort: Maester auto-discovers the environment and, if
# none is reachable, warns and skips those tests rather than failing. We also wrap
# the connect so that no single optional service can abort the run — the essential
# Graph sign-in is enforced by the Get-MgContext check immediately below.
$connectArgs = @{ Service = 'All' }
if ($UseDeviceCode) { $connectArgs['UseDeviceCode'] = $true }
try {
    Connect-Maester @connectArgs
} catch {
    Write-Host "   A service connection step reported a problem and was skipped:" -ForegroundColor Yellow
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Continuing — tests for any unreachable service will be skipped." -ForegroundColor Yellow
}

# Confirm the essential Graph sign-in completed before spending time on tests.
# (A Dataverse/Copilot or other optional-service hiccup won't trip this; only a
# failed core sign-in will.)
$ctx = Get-MgContext
if (-not $ctx) {
    throw "Sign-in did not complete. Please re-run the script and finish the login."
}
Write-Host ("   Signed in to tenant {0} as {1}." -f $ctx.TenantId, $ctx.Account) -ForegroundColor Green

# ----------------------------------------------------------------------------
# 4. Run the tests and write the JSON results
# ----------------------------------------------------------------------------
Write-Step "Running the security tests — please wait, this can take a few minutes..."
Invoke-Maester -OutputJsonFile $OutputFile

# Make sure the Maester results were actually written before we go further.
if (-not (Test-Path $OutputFile)) {
    throw "Expected results file was not created at $OutputFile. Please re-run the script."
}

# ----------------------------------------------------------------------------
# 5. Tell them where the file is and how to hand it back
# ----------------------------------------------------------------------------
$sizeKb = [math]::Round((Get-Item $OutputFile).Length / 1KB, 1)
Write-Host "`n============================================================" -ForegroundColor Green
Write-Host " Done. Results written to:" -ForegroundColor Green
Write-Host "   Maester  : $OutputFile  ($sizeKb KB)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To send the results to your Statu consultant:" -ForegroundColor Cyan
Write-Host "  1. Find the Maester file at:" -ForegroundColor White
Write-Host "       $OutputFile" -ForegroundColor White
Write-Host "  2. Email it back to us." -ForegroundColor White
Write-Host ""
Write-Host "The file contains test results only — no passwords or secrets." -ForegroundColor DarkGray
