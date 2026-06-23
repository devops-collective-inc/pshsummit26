#########################
## Script that uses parameters, parameter types and parameter validation:
#########################

param (
    [string]$ComputerName,
    [string]$ServiceName,
    [ValidateSet("Get", "Start", "Stop", "Restart")]
    [string]$Action,
    [PSCredential]$Credential
)

switch ($Action.ToLower()) {
    "get" {
        $service = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
            Get-Service -Name $using:ServiceName
        }

        $service | Format-Table Name, Status, StartType
    }
    "start" {
        $service = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
            Start-Service -Name $using:ServiceName
            Get-Service -Name $using:ServiceName
        }

        $service | Format-Table Name, Status, StartType
    }
    "stop" {
        $service = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
            Stop-Service -Name $using:ServiceName -Verbose
            Get-Service -Name $using:ServiceName
        }

        $service | Format-Table Name, Status, StartType
    }
    "restart" {
        $service = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock {
            Restart-Service -Name $using:ServiceName
            Get-Service -Name $using:ServiceName
        }

        $service | Format-Table Name, Status, StartType
    }
    default {
        Write-Error "Invalid action specified. Use 'start', 'stop', or 'restart'."
    }
}
