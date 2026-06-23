#########################
## Script that uses comment based help documentation and a function:
#########################


<#
.SYNOPSIS
Manage Summit services remotely (get, start, stop, restart).

.DESCRIPTION
This script provides small wrapper functions to get and control a named Windows
service on a remote computer using `Invoke-Command`. It exposes a simple
parameterized interface at the top-level so it can be used interactively or
as part of automation.

.PARAMETER ComputerName
The target computer where the service is running. Accepts DNS name or IP.

.PARAMETER ServiceName
The name of the Windows service to manage (as used by `Get-Service`).

.PARAMETER Action
The action to perform. Valid values are: `Get`, `Start`, `Stop`, `Restart`.

.PARAMETER Credential
A PSCredential object used for remote connections where alternate
credentials are required.

.EXAMPLE
PS> .\3-Functions-1.ps1 -ComputerName srv01 -ServiceName "Spooler" -Action Get

.EXAMPLE
PS> .\3-Functions-1.ps1 -ComputerName srv01 -ServiceName "Spooler" -Action Stop

.EXAMPLE
PS> .\3-Functions-1.ps1 -ComputerName srv01 -ServiceName "Spooler" -Action Start

.NOTES
Author: Generated documentation
#>
param (
    [string]$ComputerName,
    [string]$ServiceName,
    [ValidateSet("Get", "Start", "Stop", "Restart")]
    [string]$Action,
    [PSCredential]$Credential
)

function Set-SummitService {
    param (
        [string]$ComputerName,
        [string]$ServiceName,
        [string]$Action,
        [PSCredential]$Credential
    )

    $scriptBlock = {
        param ($ServiceName, $Action)
        switch ($Action) {
            "Get" { Get-Service -Name $ServiceName | Format-Table Name, Status, StartType }
            "Start" { Start-Service -Name $ServiceName; Get-Service -Name $ServiceName | Format-Table Name, Status, StartType }
            "Stop" { Stop-Service -Name $ServiceName; Get-Service -Name $ServiceName | Format-Table Name, Status, StartType }
            "Restart" { Restart-Service -Name $ServiceName; Get-Service -Name $ServiceName | Format-Table Name, Status, StartType }
        }
    }

    Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $ServiceName, $Action
}

switch ($Action.ToLower()) {
    "get" {
        Set-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Action "Get" -Credential $Credential
    }
    "start" {
        Set-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Action "Start" -Credential $Credential
    }
    "stop" {
        Set-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Action "Stop" -Credential $Credential
    }
    "restart" {
        Set-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Action "Restart" -Credential $Credential
    }
    default {
        Write-Error "Invalid action specified. Use 'start', 'stop', or 'restart'."
    }
}
