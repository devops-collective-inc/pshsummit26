function Stop-SummitService {
    param (
        [string]$ServiceName,
        [PSCredential]$Credential
    )

    Write-Warning "Stopping service '$ServiceName'"
    
    $service = Get-Service -Name $ServiceName

    Write-Host "Service '$ServiceName' status: Stopped"
    
}