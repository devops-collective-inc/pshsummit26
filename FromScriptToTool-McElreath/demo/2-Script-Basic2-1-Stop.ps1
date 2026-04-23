#########################
## Basic Script with hard coded variables:
#########################

$ComputerName = "dc"
$ServiceName = "bits"

$credential = Get-Credential -Message "Enter credentials for $ComputerName" -UserName "home\matt"

Write-Warning "Stopping the service $ServiceName on $ComputerName."
Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
    Stop-Service -Name $using:ServiceName
    Get-Service -Name $using:ServiceName | Format-Table Name, Status, StartType
}
