function Start-WEFDemo {

    # Cleanup
    Get-EventSubscriber | Where-Object SourceIdentifier -like 'WEF_Demo*' |
        Unregister-Event -Force -ErrorAction SilentlyContinue
    Get-Event | Remove-Event -ErrorAction SilentlyContinue

    # Ensure sources exist
    New-EventLog -LogName Application -Source SummitWEF -ErrorAction SilentlyContinue
    New-EventLog -LogName Application -Source SummitWEF-Derived -ErrorAction SilentlyContinue

    # ---- Watcher 1: Incoming "Forwarded" Event ----
    $incomingQuery = New-Object System.Diagnostics.Eventing.Reader.EventLogQuery(
        "Application",
        [System.Diagnostics.Eventing.Reader.PathType]::LogName,
        "*[System[Provider[@Name='SummitWEF'] and (EventID=1000)]]"
    )

    $global:IncomingWatcher = New-Object System.Diagnostics.Eventing.Reader.EventLogWatcher(
        $incomingQuery,
        $null,
        $true
    )

    Register-ObjectEvent -InputObject $global:IncomingWatcher `
        -EventName EventRecordWritten `
        -SourceIdentifier WEF_Demo_Incoming `
        -Action {
            $rec = $Event.SourceEventArgs.EventRecord
            Write-Host "📨 EVENT 1000 received: $($rec.FormatDescription())" -ForegroundColor Cyan

            # 🔗 Chain reaction: emit a derived event
            Write-EventLog `
                -LogName Application `
                -Source SummitWEF-Derived `
                -EventId 2000 `
                -EntryType Warning `
                -Message "Derived event created from Event 1000 on $($rec.MachineName)"
        } | Out-Null

    $global:IncomingWatcher.Enabled = $true

    # ---- Watcher 2: Derived Decision Event ----
    $derivedQuery = New-Object System.Diagnostics.Eventing.Reader.EventLogQuery(
        "Application",
        [System.Diagnostics.Eventing.Reader.PathType]::LogName,
        "*[System[Provider[@Name='SummitWEF-Derived'] and (EventID=2000)]]"
    )

    $global:DerivedWatcher = New-Object System.Diagnostics.Eventing.Reader.EventLogWatcher(
        $derivedQuery,
        $null,
        $true
    )

    Register-ObjectEvent -InputObject $global:DerivedWatcher `
        -EventName EventRecordWritten `
        -SourceIdentifier WEF_Demo_Derived `
        -Action {
            $rec = $Event.SourceEventArgs.EventRecord

            Write-Host "🚨 EVENT 2000 detected — triggering automation!" -ForegroundColor Red
            Write-Host "⚙️  Simulating response for $($rec.MachineName)" -ForegroundColor Magenta
        } | Out-Null

    $global:DerivedWatcher.Enabled = $true

    Write-Host "`n📡 WEF Event Chain Demo LIVE" -ForegroundColor Green
    Write-Host "Trigger the chain with:" -ForegroundColor DarkGray
    Write-Host "  Write-EventLog -LogName Application -Source SummitWEF -EventId 1000 -EntryType Information -Message 'Initial signal'" -ForegroundColor DarkGray
}
