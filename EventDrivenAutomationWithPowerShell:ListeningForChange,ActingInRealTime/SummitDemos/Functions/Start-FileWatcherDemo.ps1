function Start-FileWatcherDemo {
<#
    Start-DemoFileWatcher.ps1
    - Starts a FileSystemWatcher demo that prints events instantly.
    - Safe to rerun; it cleans any prior subscriptions first.
#>

# -- Settings
$global:DemoFolder = Join-Path $env:TEMP 'DemoEvents'
$global:FswVarName = 'fsw_demo'          # variable name to hold the watcher
$global:DemoPrefix = 'FSWDemo_'          # prefix for SourceIdentifiers

# -- Ensure demo folder exists
if (-not (Test-Path $global:DemoFolder)) {
    New-Item -ItemType Directory -Path $global:DemoFolder -Force | Out-Null
}

# -- Remove any previous event subscriptions from this demo
Get-EventSubscriber |
    Where-Object SourceIdentifier -like "$($global:DemoPrefix)*" |
    Unregister-Event -ErrorAction SilentlyContinue

# -- Stop and dispose any existing watcher variable from a prior run
if (Get-Variable -Name $global:FswVarName -Scope Global -ErrorAction SilentlyContinue) {
    try {
        $w = Get-Variable -Name $global:FswVarName -Scope Global -ValueOnly
        if ($w) {
            $w.EnableRaisingEvents = $false
            $w.Dispose()
        }
    } catch {}
    Remove-Variable -Name $global:FswVarName -Scope Global -ErrorAction SilentlyContinue
}

# -- Create a fresh watcher
$global:fsw_demo = New-Object System.IO.FileSystemWatcher $global:DemoFolder, '*'
$global:fsw_demo.IncludeSubdirectories = $false
$global:fsw_demo.EnableRaisingEvents   = $true

# -- Register event handlers (colorful, easy to see from stage)
Register-ObjectEvent -InputObject $global:fsw_demo -EventName Created -SourceIdentifier ($global:DemoPrefix + 'Created') -Action {
    Write-Host "🟢 Created: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Green
} | Out-Null

Register-ObjectEvent -InputObject $global:fsw_demo -EventName Changed -SourceIdentifier ($global:DemoPrefix + 'Changed') -Action {
    Write-Host "🟡 Changed: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Yellow
} | Out-Null

Register-ObjectEvent -InputObject $global:fsw_demo -EventName Renamed -SourceIdentifier ($global:DemoPrefix + 'Renamed') -Action {
    Write-Host "🔵 Renamed: $($Event.SourceEventArgs.OldFullPath) -> $($Event.SourceEventArgs.FullPath)" -ForegroundColor Cyan
} | Out-Null

Register-ObjectEvent -InputObject $global:fsw_demo -EventName Deleted -SourceIdentifier ($global:DemoPrefix + 'Deleted') -Action {
    Write-Host "🔴 Deleted: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Red
} | Out-Null

Write-Host "`n✅ FileSystemWatcher is LIVE on: $($global:DemoFolder)" -ForegroundColor Green

# -- Quick helper: generate a short burst to prove it works
$probe = Join-Path $global:DemoFolder 'demo.txt'
"hello" | Out-File $probe -Encoding UTF8
"world" | Add-Content $probe
Rename-Item $probe ($probe -replace '\.txt$','.log')
Remove-Item ($probe -replace '\.txt$','.log')

Write-Host "Tip: open another console and run:" -ForegroundColor DarkGray
Write-Host "  `"New-Item -Path $env:TEMP\DemoEvents\test.txt -ItemType File`"" -ForegroundColor DarkGray
}