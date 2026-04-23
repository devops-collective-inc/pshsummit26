#########################
## Basic Script Example:
#########################

$credential = Get-Credential -UserName "home\matt" -Message "Enter password for home\matt"

Invoke-Command -ComputerName "dc" -Credential $credential -ScriptBlock {
    Get-Service -Name "bits"
}

Invoke-Command -ComputerName "dc" -Credential $credential -ScriptBlock {
    Start-Service -Name "bits"
    Get-Service -Name "bits"
}

Invoke-Command -ComputerName "dc" -Credential $credential -ScriptBlock {
    Stop-Service -Name "bits"
    Get-Service -Name "bits"
}