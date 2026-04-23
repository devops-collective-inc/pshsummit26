<#
.SYNOPSIS
Perform service operations using Summit service helper functions.

.DESCRIPTION
Wrapper that invokes the module's service helper functions (`Get-SummitService`,
`Start-SummitService`, `Stop-SummitService`, `Restart-SummitService`) against a
target computer and service name. Use `-Action` to choose the operation.

.PARAMETER ComputerName
The target computer where the service is hosted.

.PARAMETER ServiceName
The name of the service to act on.

.PARAMETER Action
The action to perform. Valid values are `Get`, `Start`, `Stop`, `Restart`.

.PARAMETER Credential
Optional PSCredential used for remote authentication when connecting to the target computer.

.EXAMPLE
Update-SummitService -ComputerName "srv01" -ServiceName "SummitSvc" -Action Restart -Credential (Get-Credential)

.NOTES
Relies on private helper functions in the module's `functions\Private` folder.
Module: Summit-Toolbox
#>
function Update-SummitService {
    [CmdletBinding()]
    param (
        [string]$ServiceName,
        [ValidateSet("Get", "Start", "Stop", "Restart")]
        [string]$Action
    )

    switch ($Action.ToLower()) {
        "get" {
            Get-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Credential $Credential
        }
        "start" {
            Start-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Credential $Credential
        }
        "stop" {
            Stop-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Credential $Credential
        }
        "restart" {
            Restart-SummitService -ComputerName $ComputerName -ServiceName $ServiceName -Credential $Credential
        }
        default {
            Write-Error "Invalid action specified. Use 'start', 'stop', or 'restart'."
        }
    }
}