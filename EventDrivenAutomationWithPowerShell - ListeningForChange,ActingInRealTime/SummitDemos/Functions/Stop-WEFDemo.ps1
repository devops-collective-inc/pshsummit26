function Stop-WEFDemo {

    # Remove event subscribers
    Get-EventSubscriber | Where-Object SourceIdentifier -like 'WEF_Demo*' |
        Unregister-Event -ErrorAction SilentlyContinue

    # Clear queued events
    Get-Event | Remove-Event -ErrorAction SilentlyContinue

    # Disable and dispose watcher
    if ($global:WEFWatcher) {
        try {
            $global:WEFWatcher.Enabled = $false
            $global:WEFWatcher.Dispose()
        } catch {}
        Remove-Variable -Name WEFWatcher -Scope Global -ErrorAction SilentlyContinue
    }

    Write-Host "🧹 WEF Demo cleaned up." -ForegroundColor Green
}
