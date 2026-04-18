function Show-FileWatcherDemoCode {
@'
# Demo 2 – FileSystemWatcher

$DemoFolder = Join-Path $env:TEMP 'DemoEvents'
$fsw = New-Object System.IO.FileSystemWatcher $DemoFolder, '*'
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents   = $true

Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier FSWDemo_Created -Action {
    Write-Host "Created: $($Event.SourceEventArgs.FullPath)"
}

Register-ObjectEvent -InputObject $fsw -EventName Changed -SourceIdentifier FSWDemo_Changed -Action {
    Write-Host "Changed: $($Event.SourceEventArgs.FullPath)"
}

Register-ObjectEvent -InputObject $fsw -EventName Renamed -SourceIdentifier FSWDemo_Renamed -Action {
    Write-Host "Renamed: $($Event.SourceEventArgs.OldFullPath) -> $($Event.SourceEventArgs.FullPath)"
}

Register-ObjectEvent -InputObject $fsw -EventName Deleted -SourceIdentifier FSWDemo_Deleted -Action {
    Write-Host "Deleted: $($Event.SourceEventArgs.FullPath)"
}
'@ | Write-Host -ForegroundColor Gray
}
