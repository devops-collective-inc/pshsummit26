function Start-ProcessStartDemoCim {
    Write-Host "[Demo] Registering CIM process start event..." -ForegroundColor Cyan

    Register-CimIndicationEvent -ClassName Win32_ProcessStartTrace -SourceIdentifier ProcStart -Action {
        Write-Host "[PROCESS] $($Event.SourceEventArgs.NewEvent.ProcessName) started" -ForegroundColor Yellow
    } | Out-Null
}
