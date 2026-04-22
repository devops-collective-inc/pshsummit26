function Reset-ProcessStartDemo {
    Write-Host "[Demo] Cleaning up event subscribers..." -ForegroundColor Magenta

    Unregister-Event -SourceIdentifier ProcStart -ErrorAction SilentlyContinue
    Remove-Event -SourceIdentifier ProcStart -ErrorAction SilentlyContinue

    Get-EventSubscriber | Format-Table -AutoSize
}
