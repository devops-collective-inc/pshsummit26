#########################
## Script using parameters for flexibility:
#########################

param (
    $ComputerName,
    $ServiceName,
    $Action,
    $Credential
)

switch ($Action) {
    "Start" {
        Write-Warning "Starting the service $ServiceName on $ComputerName."
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            Start-Service -Name $using:ServiceName
            Get-Service -Name $using:ServiceName | Format-Table Name, Status, StartType
        }
    }
    "Stop" {
        Write-Warning "Stopping the service $ServiceName on $ComputerName."
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            Stop-Service -Name $using:ServiceName
            Get-Service -Name $using:ServiceName | Format-Table Name, Status, StartType
        }
    }
    "Restart" {
        Write-Warning "Restarting the service $ServiceName on $ComputerName."
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            Restart-Service -Name $using:ServiceName
            Get-Service -Name $using:ServiceName | Format-Table Name, Status, StartType
        }
    }
    Default {
        Write-Warning "Invalid action specified. Please use 'Start', 'Stop', or 'Restart'."
    }
}
