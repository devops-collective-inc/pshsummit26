$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -------------------------------------------------------------------------------------------------
# Chocolatey Core Apps Installer (MDT-safe)
# - Reads core_apps.config in the same folder as this script
# - Ensures Chocolatey exists (optionally bootstraps via New-ClientReg-Admin.ps1 if present)
# - Installs packages one-by-one with retries
# - Returns 0 (success), 3010 (reboot required), or a real Chocolatey exit code on failure
# -------------------------------------------------------------------------------------------------

# --- Logging (Transcript) ------------------------------------------------------------------------
$logRoot = 'C:\Windows\Temp\Choco'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$logFile = Join-Path $logRoot ("ChocolateyCoreAppsInstall_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

try { Start-Transcript -Path $logFile -Append | Out-Null } catch { }

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message
    )
    Write-Host $Message
}

function Resolve-ChocoExe {
    $candidates = @()

    if ($env:ProgramData) {
        $c1 = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
        if (Test-Path -LiteralPath $c1) { $candidates += $c1 }
    }
    if ($env:ChocolateyInstall) {
        $c2 = Join-Path $env:ChocolateyInstall 'bin\choco.exe'
        if (Test-Path -LiteralPath $c2) { $candidates += $c2 }
    }

    if ($candidates.Count -gt 0) { return $candidates[0] }

    $cmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($cmd -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }

    return $null
}

function Get-CorePackagesFromConfig {
    param(
        [Parameter(Mandatory)][string]$ConfigPath
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Core apps config not found: $ConfigPath"
    }

    [xml]$xml = Get-Content -LiteralPath $ConfigPath -Encoding UTF8

    if (-not $xml.packages -or -not $xml.packages.package) {
        throw "No <package id=""..."" /> entries were found in: $ConfigPath"
    }

    $ids = @()
    foreach ($p in $xml.packages.package) {
        if ($p.id -and ($p.id.Trim().Length -gt 0)) {
            $ids += $p.id.Trim()
        }
    }

    $ids = $ids | Select-Object -Unique
    if ($ids.Count -eq 0) { throw "Config contained no valid package IDs: $ConfigPath" }

    return $ids
}

function Invoke-ChocoInstall {
    param(
        [Parameter(Mandatory)][string]$ChocoExe,
        [Parameter(Mandatory)][string]$PackageId,
        [int]$MaxAttempts = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-Log ("[INFO] Installing '{0}' (attempt {1}/{2})" -f $PackageId, $attempt, $MaxAttempts)

        # Keep output controlled for MDT logs; no progress bar.
        & $ChocoExe install $PackageId -y --no-progress --limit-output
        $code = [int]$LASTEXITCODE

        if ($code -eq 0) {
            Write-Log ("[OK] '{0}' installed/verified successfully." -f $PackageId)
            return 0
        }

        if ($code -eq 3010) {
            Write-Log ("[OK] '{0}' installed; reboot required (3010)." -f $PackageId)
            return 3010
        }

        Write-Log ("[WARN] '{0}' returned exit code {1}." -f $PackageId, $code)

        # Retry only if attempts remain
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds 5
            continue
        }

        # No more retries -> fail with the real Chocolatey exit code
        throw "Package '$PackageId' failed after $MaxAttempts attempts (exit code $code)."
    }
}

try {
    Write-Log ("[INFO] Log: {0}" -f $logFile)

    $configPath = Join-Path $PSScriptRoot 'core_apps.config'

    # --- Ensure Chocolatey exists (bootstrap if needed) ------------------------------------------
    $chocoExe = Resolve-ChocoExe
    if (-not $chocoExe) {
        Write-Log "[WARN] choco.exe not found. Attempting bootstrap via New-ClientReg-Admin.ps1 (if present)."

        $bootstrapCandidates = @(
            (Join-Path $PSScriptRoot 'New-ClientReg-Admin.ps1'),
            (Join-Path $PSScriptRoot 'New-ClientReg-Admin-ProGet.ps1')
        )

        $bootstrap = $bootstrapCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $bootstrap) {
            throw "Chocolatey is missing and no bootstrap script was found beside this installer."
        }

        Write-Log ("[INFO] Bootstrapping Chocolatey: {0}" -f $bootstrap)
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap
        $bCode = [int]$LASTEXITCODE
        if ($bCode -ne 0 -and $bCode -ne 3010) {
            throw "Bootstrap failed with exit code $bCode."
        }

        $chocoExe = Resolve-ChocoExe
        if (-not $chocoExe) {
            throw "Bootstrap completed but choco.exe is still not available."
        }

        Write-Log ("[OK] Chocolatey found at: {0}" -f $chocoExe)
    } else {
        Write-Log ("[OK] Chocolatey found at: {0}" -f $chocoExe)
    }

    # --- Read config and install packages --------------------------------------------------------
    $packages = Get-CorePackagesFromConfig -ConfigPath $configPath
    Write-Log ("[INFO] Core apps from config: {0}" -f ($packages -join ', '))

    $needsReboot = $false

    foreach ($pkg in $packages) {
        $code = Invoke-ChocoInstall -ChocoExe $chocoExe -PackageId $pkg -MaxAttempts 2
        if ($code -eq 3010) { $needsReboot = $true }
    }

    if ($needsReboot) {
        Write-Log "[INFO] One or more installs requested a reboot."
        exit 3010
    }

    Write-Log "[OK] Core apps installation completed successfully."
    exit 0
}
catch {
    Write-Log ("[ERROR] {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    try { Stop-Transcript | Out-Null } catch { }
}
