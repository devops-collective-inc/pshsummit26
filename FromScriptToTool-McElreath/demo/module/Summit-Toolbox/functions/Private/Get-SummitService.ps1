function Get-SummitService {
    param (
        [string]$ServiceName,
        [PSCredential]$Credential
    )

    Write-Warning "Getting service '$ServiceName'..."

    $service = Get-Service -Name $ServiceName
    
    Write-Host "Service '$ServiceName' status: $($service.Status)"
}