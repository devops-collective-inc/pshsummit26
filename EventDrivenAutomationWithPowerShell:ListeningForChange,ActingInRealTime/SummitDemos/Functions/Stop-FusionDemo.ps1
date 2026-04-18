function Stop-FusionDemo {
<#
    Cleanly stops all Fusion demo components.
#>

    # Unsubscribe all events
    Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
    Get-Event | Remove-Event -ErrorAction SilentlyContinue

    # Dispose watcher
    if ($global:fsw) {
        $global:fsw.EnableRaisingEvents = $false
        $global:fsw.Dispose()
        Remove-Variable -Name fsw -Scope Global -ErrorAction SilentlyContinue
    }

    # Dispose timer
    if ($global:timer) {
        $global:timer.Stop()
        $global:timer.Dispose()
        Remove-Variable -Name timer -Scope Global -ErrorAction SilentlyContinue
    }

    # Remove folder
    Remove-Item -Recurse -Force "$env:TEMP\FusionDemo" -ErrorAction SilentlyContinue

    Write-Host "🧹 Fusion Demo cleaned up." -ForegroundColor Green
}
