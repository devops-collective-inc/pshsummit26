function Test-WEFDemoVerbose {

    Write-Host "`n🔍 Testing WEF Demo setup..." -ForegroundColor Cyan

    # 1. Check event source
    $sourceExists = [System.Diagnostics.EventLog]::SourceExists("SummitWEF")
    if ($sourceExists) {
        Write-Host "✔ Event source 'SummitWEF' exists." -ForegroundColor Green
    } else {
        Write-Host "✖ Event source 'SummitWEF' does NOT exist." -ForegroundColor Red
        Write-Host "Creating it now..."
        New-EventLog -LogName Application -Source SummitWEF -ErrorAction SilentlyContinue
    }

    # 2. Check watcher
    if ($global:WEFWatcher -and $global:WEFWatcher.Enabled) {
        Write-Host "✔ WEFWatcher is active and enabled." -ForegroundColor Green
    } else {
        Write-Host "✖ WEFWatcher is not running." -ForegroundColor Red
        Write-Host "Start the demo with Start-WEFDemo before testing." -ForegroundColor Yellow
        return
    }

    # 3. Write a test event
    Write-Host "📝 Writing test event..." -ForegroundColor DarkGray
    Write-EventLog -LogName Application -Source SummitWEF -EventId 999 -EntryType Information -Message "WEF Demo Test Event"

    Start-Sleep -Milliseconds 300

    # 4. Verify event landed
    $evt = Get-WinEvent -LogName Application -MaxEvents 20 |
        Where-Object { $_.Id -eq 999 -and $_.ProviderName -eq "SummitWEF" } |
        Select-Object -First 1

    if ($evt) {
        Write-Host "✔ Test event successfully written to Application log." -ForegroundColor Green
        Write-Host "✔ WEF Demo pipeline is working." -ForegroundColor Green
    } else {
        Write-Host "✖ Test event did NOT appear in Application log." -ForegroundColor Red
        Write-Host "This indicates a local logging restriction or source mismatch." -ForegroundColor Yellow
    }

    Write-Host "`nTest complete.`n" -ForegroundColor Cyan
}
