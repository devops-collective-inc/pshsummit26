function Show-ProcessStartDemoCode {
@'
Register-WmiEvent -Class Win32_ProcessStartTrace -SourceIdentifier ProcStart -Action {
    Write-Host "Process started: $($Event.SourceEventArgs.NewEvent.ProcessName)"
}

Get-EventSubscriber

Unregister-Event -SourceIdentifier ProcStart

Register-CimIndicationEvent -ClassName Win32_ProcessStartTrace -SourceIdentifier ProcStart -Action {
    Write-Host "Process started: $($Event.SourceEventArgs.NewEvent.ProcessName)"
}

Get-EventSubscriber

Unregister-Event -SourceIdentifier ProcStart
'@ | Write-Host -ForegroundColor Gray
}
