<#
    .SYNOPSIS
    This script is used to add or remove a Microsoft Edge extension to the ExtensionInstallForceList in the registry.
    .DESCRIPTION
    This script checks if the specified extension is already in the ExtensionInstallForceList. If it is not, it adds the extension to the list. If it is, it exits gracefully. The script can also be used to remove the extension from the force list if it is already present by uncommenting the relevant line.  Don't nerd snipe me not every script you've ever written was a 1000 line masterpiece, some of them are just quick and dirty scripts to get a job done. This is one of those.
    .PARAMETER extensionId
    The ID of the extension to be added to or removed from the force list.
    .EXAMPLE
    .\ManageEdgeExtensionForceList.ps1 -extensionId oplgganppgjhpihgciiifejplnnpodak
    This command adds the Microsoft Graph X-Ray extension to the Edge ExtensionInstallForceList.
    .NOTES
    Ensure you have the necessary permissions to modify the registry and manage Edge extensions. Use with caution, as incorrect modifications to the registry can cause system instability.
#>
Param(
    [Parameter(Mandatory=$false,HelpMessage="ID of the extension to be added to force list. Default is Microsoft Editor extension")]
    [ValidatePattern('^[a-z]{32}$')]
    [string]$extensionId = 'oplgganppgjhpihgciiifejplnnpodak'
)
Function Get-RegistryKeyPropertyAndValue {
    Param(
        [Parameter(Mandatory)]
        [string[]]$path
    )
    Foreach ($entry in $path) {
        Try {
            Push-Location $entry -ErrorAction STOP
            Get-Item . | Select -ExpandProperty Property | Foreach {
                New-Object psobject -Property @{
                    "Property" = $_
                    "Value"    = (Get-ItemProperty -Path . -Name $_).$_
                }

            }
            Pop-Location
        }
        Catch {
            Write-Host "Path Not Found -- $path"
            Write-Host $error[0]
        }
    }
}

Function Check-Extension{
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [psobject[]]$regObj
    )
    Begin{}
    Process{
        
            If($($regObj.value -like "$extensionId*")){
                Write-Output $true
            }
    }
    End{}

}

Function Add-ExtensionToForceList{
    Param(
        [Parameter(Mandatory)]
        [string]$extensionId
    )
    
    $path = "HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    $forceListProperties = Get-RegistryKeyPropertyAndValue -path $path
    
    If (-Not ($forceListProperties | Check-Extension)){
        $name = $forceListProperties.count + 1
        $value = $extensionId
        $updateURL=';https://edge.microsoft.com/extensionwebstorebase/v1/crx'
        Write-Host "Adding $name to $path with value $value"
        Try{    
            New-ItemProperty -Path $path -Name $name -Value $("$value$updateURL") -PropertyType String
            Write-Host "Extension added to force list"   
            Exit 0}
        Catch{
            Write-Host "Failed to add extension to force list"
            Exit 1
        }
    }Else{
        Write-Host "Extension already in force list"
        Exit 2
    }
}

Function Remove-ExtensionFromForceList{
    Param(
        [Parameter(Mandatory)]
        [string]$extensionId
    )
    
    $path = "HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    $forceListProperties = Get-RegistryKeyPropertyAndValue -path $path
    
    If ($forceListProperties | Check-Extension){
        $name  = ($forceListProperties | Where-Object {$_.value -like "$extensionId*"}).property
        $value = ($forceListProperties | Where-Object {$_.value -like "$extensionId*"}).value
        Write-Host "Removing $name with value $value from $path"
        Try{    
            Remove-ItemProperty -Path $path -Name $name -ErrorAction Stop
            Write-Host "Extension removed from force list"   
            Exit 0}
        Catch{
            Write-Host "Failed to remove extension from force list"
            Exit 1
        }
    }Else{
        Write-Host "Extension not in force list"
        Exit 2
    }
}

Add-ExtensionToForceList      -extensionId $extensionId
# Remove-ExtensionFromForceList -extensionId $extensionId
