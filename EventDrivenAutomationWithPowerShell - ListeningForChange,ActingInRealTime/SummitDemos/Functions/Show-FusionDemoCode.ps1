function Show-FusionDemoCode {
@'
# Fusion Demo – WMI + FileSystemWatcher + Timer

# 1) WMI: Process Start
Register-WmiEvent -Class Win32_ProcessStartTrace -SourceIdentifier Fusion_ProcessStart -Action {
    Write-Host "PROCESS STARTED: $($Event.SourceEventArgs.NewEvent.ProcessName)"
}

# 2) FileSystemWatcher
$folder = Join-Path $env:TEMP 'FusionDemo'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$fsw = New-Object System.IO.FileSystemWatcher $folder, '*'
$fsw.EnableRaisingEvents = $true
Register-ObjectEvent $fsw Created -SourceIdentifier Fusion_FileCreated -Action {
    Write-Host "FILE CREATED: $($Event.SourceEventArgs.FullPath)"
}

# 3) Timer
$timer = New-Object System.Timers.Timer 2000
$timer.AutoReset = $true
$timer.Enabled   = $true
Register-ObjectEvent $timer Elapsed -SourceIdentifier Fusion_Timer -Action {
    Write-Host "TIMER TICK: $(Get-Date -Format HH:mm:ss)"
}
'@ | Write-Host -ForegroundColor Gray
}
