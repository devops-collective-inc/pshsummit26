function Start-ProcessStartDemoWmi {
    Write-Host "[Demo] Registering WMI process start event..." -ForegroundColor Cyan

    Register-WmiEvent -Class Win32_ProcessStartTrace -SourceIdentifier ProcStart -Action {
        Write-Host "Process started: $($Event.SourceEventArgs.NewEvent.ProcessName)" -ForegroundColor Yellow
    }

    Get-EventSubscriber | Format-Table -AutoSize
}
