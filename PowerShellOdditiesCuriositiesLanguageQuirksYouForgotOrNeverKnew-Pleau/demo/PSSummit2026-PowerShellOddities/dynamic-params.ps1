<#
=======================
The 'dynamicparam' keyword
=======================

What is it: keyword
What it does: Dynamic parameters are parameters of a cmdlet, function, or script that are available only under certain conditions. 
Link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.6#dynamic-parameters 

Example below.
#>

function Get-Animal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Mammal", "Bird")]
        [string]
        $Species
    )
    dynamicparam {
        if ($species -eq 'Mammal') {
            # Define parameter attributes
            $paramAttributes = New-Object -Type System.Management.Automation.ParameterAttribute
            $paramAttributes.Mandatory = $true
            $validateSet = New-Object -Type System.Management.Automation.ValidateSetAttribute("Canine", "Feline")
            $paramAttributesCollect = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $paramAttributesCollect.Add($paramAttributes)
            $paramAttributesCollect.Add($validateSet)
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("MammalType", [string], $paramAttributesCollect)
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add("MammalType", $dynParam1)
            return $paramDictionary
        }
    }
    begin {
        $MammalType = $PSBoundParameters['MammalType']
    }
    process {
        if ($MammalType) {
            'mammal'
        } else {
            'non mammal'
        }
    }
}
