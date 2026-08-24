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
    No app registration and nothing permanent to install. You sign in with an
    ADMINISTRATOR account; Maester reads your security configuration (READ ONLY —
    it never changes anything) and writes the results to a single .json file.

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
    Permissions  : sign in with an administrator account holding the Global Reader
                   (or Security Reader / Global Administrator) role. A normal user
                   account will still run, but most tests will be skipped and the
                   result cannot be used.
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

# PowerShellGet needs the NuGet package provider before it can install anything.
# If it isn't present it bootstraps itself into $env:ProgramFiles\PackageManagement,
# which fails on a normal user account with:
#   "Install-Package: Administrator rights are required to install or update."
# That message is misleading here — our Install-Module calls are already scoped to
# CurrentUser; it's the provider bootstrap that wants the machine-wide folder. So
# install the provider for the current user first, before anything triggers it.
$haveNuGet = $false
try {
    $haveNuGet = [bool](Get-PackageProvider -Name NuGet -ErrorAction Stop)
} catch {
    $haveNuGet = $false
}
if (-not $haveNuGet) {
    Write-Host "   Installing the NuGet package provider (your user account only)..." -ForegroundColor DarkGray
    # Non-fatal: if even the user-scoped provider install is blocked, carry on —
    # Install-RequiredModule falls back to PSResourceGet, which needs no provider.
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    } catch {
        Write-Host "   Couldn't install it; will use PSResourceGet instead." -ForegroundColor DarkGray
    }
}

# Install one module into the current user's profile.
#
# PowerShellGet v2 (Install-Module) is the proven path, but it always goes through
# the NuGet provider. When that provider is missing or blocked, PowerShellGet fails
# with "Administrator rights are required to install or update" even though we ask
# for -Scope CurrentUser. PSResourceGet (Install-PSResource) ships with PowerShell
# 7.4+ and talks to the gallery directly, so it has no such dependency — use it as
# the fallback. PSGallery speaks the NuGet v2 protocol, so dependencies (the
# Microsoft.Graph modules Maester needs, for example) are still resolved for us.
function Install-RequiredModule {
    param([Parameter(Mandatory)][string]$Name)

    # -Force (and -TrustRepository below) also keeps PSGallery's "untrusted
    # repository" prompt from halting the run, without changing the repository's
    # saved trust setting.
    try {
        if ($Name -eq 'Pester') {
            # Windows ships a Microsoft-signed Pester 3.4 that PS7 can see, so the
            # publisher check has to be waived to install a current version.
            Install-Module -Name $Name -Force -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop
        } else {
            Install-Module -Name $Name -Force -Scope CurrentUser -ErrorAction Stop
        }
        return
    } catch {
        if (-not (Get-Command Install-PSResource -ErrorAction SilentlyContinue)) { throw }
        Write-Host "   PowerShellGet couldn't install $Name — retrying with PSResourceGet." -ForegroundColor DarkGray
        Write-Host "   ($($_.Exception.Message.Trim()))" -ForegroundColor DarkGray
    }

    Install-PSResource -Name $Name -Scope CurrentUser -TrustRepository -Quiet -ErrorAction Stop
}

# The service modules are required for full coverage: 'Connect-Maester -Service All'
# uses them to reach Exchange Online / Purview (ExchangeOnlineManagement), Teams
# (MicrosoftTeams) and Azure (Az.Accounts). Without them those connections are
# skipped and ~300 tests don't run. Everything goes into the current user's profile.
try {
    foreach ($moduleName in @('Pester', 'Maester', 'ExchangeOnlineManagement', 'MicrosoftTeams', 'Az.Accounts')) {
        Install-RequiredModule -Name $moduleName
    }
} catch {
    Write-Host ""
    Write-Host "   The modules could not be installed:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Nothing was changed on your machine. Please send this message to" -ForegroundColor Yellow
    Write-Host "   your Statu consultant (a screenshot is fine) and we'll help you." -ForegroundColor Yellow
    throw
}

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

Write-Host "   IMPORTANT: sign in with your ADMINISTRATOR account - the one that" -ForegroundColor Yellow
Write-Host "   can open https://admin.microsoft.com. If you have a separate admin" -ForegroundColor Yellow
Write-Host "   account, use that one, not your everyday account. If the wrong" -ForegroundColor Yellow
Write-Host "   account is already filled in, choose 'Use another account'." -ForegroundColor Yellow
Write-Host ""
if ($UseDeviceCode) {
    Write-Host "   You'll see a message with a short code. Open" -ForegroundColor Yellow
    Write-Host "   https://microsoft.com/devicelogin in another browser tab," -ForegroundColor Yellow
    Write-Host "   enter the code, and approve the read-only access." -ForegroundColor Yellow
} else {
    Write-Host "   A browser window will open — sign in and approve the" -ForegroundColor Yellow
    Write-Host "   read-only access." -ForegroundColor Yellow
}
Write-Host "   Full coverage: expect several sign-in prompts (Entra/Graph," -ForegroundColor Yellow
Write-Host "   Exchange Online, Teams, Purview, Azure) - use the SAME admin" -ForegroundColor Yellow
Write-Host "   account for every one of them." -ForegroundColor Yellow
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
Write-Host "   ^ Check that this is your ADMINISTRATOR account. If it isn't, press" -ForegroundColor Yellow
Write-Host "     Ctrl+C, sign out in your browser, and run the script again." -ForegroundColor Yellow

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
