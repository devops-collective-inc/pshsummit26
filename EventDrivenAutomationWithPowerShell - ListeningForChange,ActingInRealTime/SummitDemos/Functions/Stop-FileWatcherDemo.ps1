function Stop-FileWatcherDemo {
<#
    Cleanly stops the FileSystemWatcher demo and removes event subscriptions.
    Safe to run even if nothing is running.
#>

    $FswVarName = 'fsw_demo'
    $DemoPrefix = 'FSWDemo_'
    $DemoFolder = Join-Path $env:TEMP 'DemoEvents'

    # Unsubscribe demo handlers
    Get-EventSubscriber |
        Where-Object SourceIdentifier -like "$DemoPrefix*" |
        Unregister-Event -ErrorAction SilentlyContinue

    # Drain queued events
    Get-Event | Remove-Event -ErrorAction SilentlyContinue

    # Dispose watcher if present
    if (Get-Variable -Name $FswVarName -Scope Global -ErrorAction SilentlyContinue) {
        try {
            $w = Get-Variable -Name $FswVarName -Scope Global -ValueOnly
            if ($w) {
                $w.EnableRaisingEvents = $false
                $w.Dispose()
            }
        } catch {}
        Remove-Variable -Name $FswVarName -Scope Global -ErrorAction SilentlyContinue
    }

    # Remove demo folder
    if (Test-Path $DemoFolder) {
        try { Remove-Item -Recurse -Force $DemoFolder -ErrorAction Stop } catch {}
    }

    Write-Host "🧹 Demo watcher stopped and cleaned up." -ForegroundColor Green
}
