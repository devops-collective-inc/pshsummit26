<#
.SYNOPSIS
Displays the provided command text.

.DESCRIPTION
A minimal helper function used for demonstrations and testing. Writes the provided
`CommandName` string to the output stream.

.PARAMETER CommandName
The text of the command to display. If omitted the function will output an empty string.

.EXAMPLE
Get-BasicCommand -CommandName "Test"
Outputs: You entered the command: Test

.NOTES
Module: Summit-Toolbox
#>
function Get-BasicCommand {
    param (
        [string]$CommandName
    )

    Write-Output "You entered the command: $CommandName"
}