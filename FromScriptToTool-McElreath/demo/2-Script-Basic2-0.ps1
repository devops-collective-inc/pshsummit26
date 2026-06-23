#########################
## Basic Script with hard coded variables:
#########################

$ComputerName = "dc"
$ServiceName = "bits"

$credential = Get-Credential -Message "Enter credentials for $ComputerName" -UserName "home\matt"

$service = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
    Get-Service -Name $using:ServiceName
}

$service | Format-Table Name, Status, StartType

if ($service.Status -eq "Running") {
    Write-Warning "The $($service.Name) service is running on $ComputerName. Stopping the service..."
    Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
        Stop-Service -Name $using:ServiceName
    }
} else {
    Write-Warning "The $($service.Name) service is not running on $ComputerName. Starting the service..."
    Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
        Start-Service -Name $using:ServiceName
    }
}

$serviceStatus = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
    Get-Service -Name $using:ServiceName
}

$serviceStatus | Format-Table Name, Status, StartType