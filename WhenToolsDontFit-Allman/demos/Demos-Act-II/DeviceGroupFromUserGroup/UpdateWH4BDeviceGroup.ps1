<#
    .SYNOPSIS
    This script will get all the EntraID-Joined, Windows 11 devices from a static user group and add them to a device group.
    .DESCRIPTION
    This script will get all the EntraID-Joined, Windows 11 devices from a static user group and add them to a device group. 
    .PARAMETER userGroupId
    The ID of the user group that contains the users whose eligible devices will be added to the device group.
    .PARAMETER deviceGroupId
    The ID of the device group that the eligible devices will be added to.
    .EXAMPLE
    . UpdateWH4BDeviceGroup.ps1 -userGroupId "123456789-1234-1234-1234-123456789012" -deviceGroupId "123456789-1234-1234-1234-123456789013"
    
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]$UserGroupId,
    [Parameter(Mandatory = $True)]
    [string]$DeviceGroupId,
    [Parameter(Mandatory = $True, HelpMessage = "The tenantId of the tenant to connect to.")]
    [string]$TenantId,
    [Parameter(Mandatory = $True, HelpMessage = "The credential to use to connect to the tenant.")]
    [pscredential]$Credential

)

Function Get-DeviceListFromUserGroupMember {
    <#
    .SYNOPSIS
    Get a list of devices owned by users in a group
    .DESCRIPTION
    This function gets a list of devices owned by users in a group.  The group id is passed as a parameter. The function uses the Microsoft Graph API to get the list of devices.
    .PARAMETER GroupId
    The group id of the user group from which to get the device list
    .EXAMPLE
    Get-DeviceListFromUserGroupMember -GroupId 123456789-1234-1234-1234-123456789012
    This example gets a list of devices owned by users in the group with the id 123456789-1234-1234-1234-123456789012
    .NOTES
    Requires the Microsoft Graph Beta PowerShell module

#>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The group id of the user group from which to get the device list", ValueFromPipeline = $true)]
        [string[]]$GroupId
    )
    Process {
        
        
        Foreach ( $Id in $GroupId  ) {
            $groupUserMembers   = Get-MgBetaGroupTransitiveMemberAsUser     -GroupId $Id -All 
            $groupDeviceMembers = Get-MgBetaGroupTransitiveMemberAsDevice   -GroupId $Id -All

            $groupUserMembers | Foreach-Object {
                
                Get-MGBetaUserOwnedDevice -UserId $_.Id
                 
            }

            If ( $($groupDeviceMembers | Measure-Object | Select-Object -ExpandProperty Count) -gt 0 ) {
                
                Write-Output $groupDeviceMembers 
            }
        }
  
    }
}

If( -not $env:LogOutputPath ) {
    Write-Warning "LogOutputPath environment variable is not set. Logging will be saved to $env:tmp"
    $env:LogOutputPath = $env:tmp
}

Start-Transcript -Path $(Join-Path $env:LogOutputPath "UpdateWH4BDeviceGroup.log") -Append
Try{
    Connect-MGGraph -ClientSecretCredential $Credential -TenantID $TenantId -NoWelcome
}
Catch{
    Write-Error -Message "Failed to connect to the Microsoft Graph API. Error: "
    Write-Host -Message "$_"
    Exit 1
}

Try{
    $userGroup          = Get-MGBetaGroup       -GroupId $userGroupId     -ErrorAction Stop
    $deviceGroup        = Get-MGBetaGroup       -GroupId $deviceGroupId   -ErrorAction Stop
    $userGroupMembers   = Get-MGBetaGroupMember -GroupId $userGroupId     -ErrorAction Stop
    $deviceGroupMembers = Get-MGBetaGroupMember -GroupId $deviceGroupId   -ErrorAction Stop
}
Catch {
    Write-Error "Failed to get the groups."
    Exit 1
}

Write-Verbose "User group: $($userGroup.DisplayName)" -Verbose
Write-Verbose "Device group: $($deviceGroup.DisplayName)" -Verbose

Write-Verbose "Getting all the devices from the user group" -Verbose
Try {
    $devicesFromUserGroup = Get-DeviceListFromUserGroupMember -GroupId $userGroupId    
}
Catch {
    Write-Error "Failed to get the devices from the user group. Error:"
    Write-Host -Message "$_"
    Exit 1
}

$eligibleDevices = $devicesFromUserGroup | 
                        Where-Object { $_.AdditionalProperties.operatingSystemVersion -like "10.0.22*" -and $_.AdditionalProperties.operatingSystem -eq "Windows" -and $_.AdditionalProperties.trustType -eq "AzureAD" }
Write-Verbose "Found $($eligibleDevices| Measure-Object | Select-Object  -ExpandProperty Count) devices that are eligible to be added to the device group"

$devicesToRemove = $deviceGroupMembers  | Where-Object {$_.Id -NotIn $eligibleDevices.Id}
$newDevices      = $eligibleDevices     | Where-Object {$_.Id -NotIn $deviceGroupMembers.Id}
Write-Verbose "New Devices: $($newDevices | Measure-Object | Select-Object  -ExpandProperty Count)"

If ($newDevices.Count -lt 1) {
    Write-Verbose "No new devices to add to the group, exiting..." -Verbose
    
}
Else {
    Foreach ($device in $newDevices) {
        
        
        Write-Verbose "Adding $($device.AdditionalProperties.displayName) to the device group" -Verbose
        Try {
            New-MgBetaGroupMember -GroupId $deviceGroupId -DirectoryObjectId $device.ID -ErrorAction Stop -Verbose
        }
        
        Catch {
            If ( $_.Exception.Message -eq "[Request_BadRequest] : One or more added object references already exist for the following modified properties: 'members'.") {
                Write-Verbose "Device $($device.AdditionalProperties.displayName) is already a member of the group" -Verbose
            }
            Else {
                Write-Error "Failed to add device $($device.AdditionalProperties.displayName) to the group. Error: $_" -Verbose
                Exit 1
            }
        }
    }
}
Stop-Transcript