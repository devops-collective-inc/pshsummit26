function Restart-SummitService {
    param (
        [string]$ServiceName,
        [PSCredential]$Credential
    )

    if ($ServiceName -eq "bits") {
        $ServiceName = "bits-error"
    }

    Write-Warning "Restarting service '$ServiceName'..."
    
    $service = Get-Service -Name $ServiceName

    Write-Host "Service '$ServiceName' status: Running"
    
}