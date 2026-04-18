function Test-WEFDemo {

    Write-Host "📨 Triggering forwarded event..." -ForegroundColor Cyan

    if (-not ($global:WEFWatcher -and $global:WEFWatcher.Enabled)) {
        Write-Host "✖ WEF watcher is not running." -ForegroundColor Red
        return
    }

    $global:WEFDemoArmed = $true

    Write-EventLog `
        -LogName Application `
        -Source SummitWEF `
        -EventId 999 `
        -EntryType Information `
        -Message "Hello Summit!"

    Start-Sleep -Milliseconds 300

    if (Test-Path (Join-Path $env:TEMP 'WEFDemoTriggered.txt')) {
        Write-Host "✅ Event caused immediate PowerShell automation" -ForegroundColor Green
    }
}