#requires -version 5.1
function Get-PSTypeAccelerator {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = 'The name of the type accelerator like CimClass.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string]$Name = "*"
    )

    $Get = ([PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get)

    $Get.GetEnumerator() | Where-Object {$_.key -like $Name} |
    ForEach-Object {
        #create a custom object to store the type name and the type itself
        [PSCustomObject]@{
            PSTypeName = 'PSTypeAccelerator'
            PSVersion  = $PSVersionTable.PSVersion
            Name       = $_.Key
            Type       = $_.Value.FullName
        }
    }
}
