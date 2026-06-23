# Summit-Toolbox.psm1
# A PowerShell module for Summit 2026 Toolmaking

function Get-SummitGreeting {
    <#
    .SYNOPSIS
        Returns a greeting message for Summit 2026.
    .DESCRIPTION
        This function provides a simple greeting for the Summit 2026 event.
    .EXAMPLE
        Get-SummitGreeting
        Returns: "Welcome to Summit 2026!"
    #>
    param()

    "Welcome to Summit 2026!"
}

#Dot source private functions.
Get-ChildItem -Path $PSScriptRoot\Functions\Private\*.ps1 | ForEach-Object { . $_.FullName }

#Dot source public functions.
Get-ChildItem -Path $PSScriptRoot\Functions\Public\*.ps1 | ForEach-Object { . $_.FullName }

# Export the functions
Export-ModuleMember -Function Get-SummitGreeting, Update-SummitService, Get-SummitOfficeUser, New-SummitUser, Get-BasicCommand, Invoke-Nonsense