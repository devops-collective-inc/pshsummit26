<#
=======================
The 'Register-ArgumentCompleter' Cmdlet
=======================

What is it: Cmdlet
What it does: Provides a way to register dynamic tab completion items 
              at runtime.
Link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter?view=powershell-7.6

Example below.
#>

# Get people from SWAPI (Star Wars API)
Register-ArgumentCompleter -CommandName Out-StarWarsCharacter -ParameterName Character -ScriptBlock {
    $people = Invoke-RestMethod -Uri 'https://swapi.dev/api/people'
    # We need to look the names with the ForEach-Object to wrap them in quotes
    # This is defensive to protect against spaces
    $people.results.name | Sort-Object | ForEach-Object {"'{0}'" -f $_}
}

function Out-StarWarsCharacter {
    param(
        # Project Name
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Character
    )
    
    "Your Character is {0}" -f $Character
}

