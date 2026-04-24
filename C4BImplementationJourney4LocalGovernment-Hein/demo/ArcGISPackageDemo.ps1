$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------
# Global Safety & TLS
# ------------------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ------------------------------------------------------------------
# Package Context
# ------------------------------------------------------------------
$toolsDir        = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageName     = $env:ChocolateyPackageName
$packageVersion  = $env:ChocolateyPackageVersion

$zipName         = 'arcgistools3.6.zip'
$zipPath         = Join-Path -Path $toolsDir -ChildPath $zipName
$expectedMsiName = 'ArcGISPro.msi'
$logPath         = Join-Path -Path $env:TEMP -ChildPath "${packageName}.${packageVersion}.log"

# ------------------------------------------------------------------
# ProGet Asset Download Configuration
# ------------------------------------------------------------------
$zipUrl          = 'https://proget/assets/Choco-Applications/content/ArcGIS/ArcGIS%20Pro/arcgistools3.6.zip'
$zipChecksum     = '0e114dd159d16f71bb06aa333b3ce898e756cfc12ddb417d21079749952bcb30'
$zipChecksumType = 'sha256'

# API key must be supplied securely by the deployment environment
$proGetAssetApiKey = '#############################'

# ------------------------------------------------------------------
# Validate Required Environment Values
# ------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($packageName)) {
    throw "Chocolatey package name environment variable is missing."
}

if ([string]::IsNullOrWhiteSpace($packageVersion)) {
    throw "Chocolatey package version environment variable is missing."
}

if ([string]::IsNullOrWhiteSpace($proGetAssetApiKey)) {
    throw "Missing ProGet asset API key. Set environment variable 'ProGetAssetApiKey' before installation."
}

# ------------------------------------------------------------------
# Clean Previous Package Artifacts
# ------------------------------------------------------------------
Write-Host "Cleaning previous package artifacts from '${toolsDir}'..."

if (Test-Path -Path $zipPath) {
    Remove-Item -Path $zipPath -Force -ErrorAction Stop
}

Get-ChildItem -Path $toolsDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -ieq '.msi' } |
    ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Unable to remove stale file '${($_.FullName)}'. Continuing."
        }
    }

# ------------------------------------------------------------------
# Download ZIP from ProGet HTTP Endpoint using X-ApiKey
# ------------------------------------------------------------------
Write-Host "Downloading ArcGIS Pro ZIP from ProGet endpoint using API key authentication..."

$headers = @{
    'X-ApiKey'   = $proGetAssetApiKey
    'User-Agent' = 'chocolatey command line'
}

try {
    Invoke-WebRequest `
        -Uri $zipUrl `
        -Headers $headers `
        -OutFile $zipPath `
        -UseBasicParsing `
        -ErrorAction Stop
}
catch {
    throw "Failed to download ArcGIS Pro ZIP from ProGet endpoint. URL: '${zipUrl}'. Error: $($_.Exception.Message)"
}

if (-not (Test-Path -Path $zipPath)) {
    throw "ZIP download failed. File not found at '${zipPath}'."
}

$fileInfo = Get-Item -Path $zipPath -ErrorAction Stop
Write-Host "Downloaded file size: $($fileInfo.Length) bytes"

if ($fileInfo.Length -le 0) {
    throw "Downloaded ZIP file is empty: '${zipPath}'"
}

# ------------------------------------------------------------------
# Validate Downloaded Content Is Not HTML/Login Page
# ------------------------------------------------------------------
$firstLine = $null
try {
    $firstLine = Get-Content -Path $zipPath -TotalCount 1 -ErrorAction Stop
}
catch {
    $firstLine = $null
}

if ($firstLine -match '<!DOCTYPE html|<html|<head|<body|<title>Log In</title>') {
    throw "Downloaded content is HTML instead of the expected ZIP. Verify the ProGet endpoint URL and API key scope. URL: '${zipUrl}'"
}

# ------------------------------------------------------------------
# Validate ZIP Checksum
# ------------------------------------------------------------------
Get-ChecksumValid -File $zipPath -Checksum $zipChecksum -ChecksumType $zipChecksumType

# ------------------------------------------------------------------
# Extract ZIP
# ------------------------------------------------------------------
Write-Host "Extracting ZIP to '${toolsDir}'..."

Get-ChocolateyUnzip -FileFullPath $zipPath -Destination $toolsDir

# ------------------------------------------------------------------
# Locate MSI Recursively
# ------------------------------------------------------------------
Write-Host "Searching recursively for '${expectedMsiName}'..."

$msiCandidates = Get-ChildItem -Path $toolsDir -Recurse -File -ErrorAction Stop |
    Where-Object { $_.Name -ieq $expectedMsiName }

if (-not $msiCandidates) {
    throw "Expected MSI '${expectedMsiName}' was not found under '${toolsDir}' after extraction."
}

if ($msiCandidates.Count -gt 1) {
    $candidateList = ($msiCandidates | Select-Object -ExpandProperty FullName) -join [Environment]::NewLine
    throw "Multiple MSI files named '${expectedMsiName}' were found. Cannot continue safely.`n${candidateList}"
}

$msiPath = $msiCandidates[0].FullName

if (-not (Test-Path -Path $msiPath)) {
    throw "Resolved MSI path does not exist: '${msiPath}'"
}

Write-Host "Resolved MSI path: ${msiPath}"

# ------------------------------------------------------------------
# Install MSI
# ------------------------------------------------------------------
Write-Host "Installing ArcGIS Pro..."

$packageArgs = @{
    packageName         = $packageName
    fileType            = 'MSI'
    file                = $msiPath
    softwareName        = 'arcgispro*'
    checksum            = '703da43c59dbbdd2bbcc47c4173e6c90a110cc6ad697127c84158ddfd35acf0e'
    checksumType        = 'sha256'
    silentArgs          = @(
        '/qn'
        '/norestart'
        'ACCEPTEULA=yes'
        'ALLUSERS=1'
        'CHECKFORUPDATESATSTARTUP=0'
        'AUTHORIZATION_TYPE=NAMED_USER'
        'LOCK_AUTH_SETTINGS=TRUE'
        'ESRI_LICENSE_HOST=111.11.11.11'
        'SOFTWARE_CLASS=Professional'
        "/l*v `"$logPath`""
    ) -join ' '
    validExitCodes      = @(0, 3010)
    useOriginalLocation = $true
}

Install-ChocolateyInstallPackage @packageArgs

Write-Host "Installation completed successfully."
Write-Host "MSI log file: ${logPath}"