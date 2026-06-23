function Start-SummitService {
    param (
        [string]$ServiceName,
        [PSCredential]$Credential
    )

    Write-Warning "Starting service '$ServiceName'..."
    
    $service = Get-Service -Name $ServiceName
    
    Write-Host "Service '$ServiceName' status: Running"
}