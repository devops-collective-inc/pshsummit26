function Show-WEFDemoCode {
@'
# WEF Demo – PowerShell reacting to forwarded events

Register-WinEvent -LogName ForwardedEvents -SourceIdentifier WEF_Demo -Action {
    Write-Host "FORWARDED EVENT: $($Event.SourceEventArgs.Message)"
}

# Simulate a forwarded event
Write-EventLog -LogName ForwardedEvents -Source EventCreate -EventId 1000 -EntryType Information -Message "Hello Summit!"
'@ | Write-Host -ForegroundColor Gray
}
