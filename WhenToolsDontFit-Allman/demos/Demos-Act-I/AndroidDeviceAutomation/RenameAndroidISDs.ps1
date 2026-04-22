<#
    .SYNOPSIS
    This script is used to Retire non-compliant Android devices and re-name android devices that don't fit the naming convention.
    .DESCRIPTION
    This script is used to Retire non-compliant Android devices and re-name android devices that don't fit the naming convention.
    It checks the membership of the specified AAD group and then checks the devices in the group for naming convention.
    .PARAMETER tenantId
    The tenantId of the tenant to connect to. 
    .PARAMETER groupId
    The group id of the AAD group to check for devices. 
    .PARAMETER credential
    The credential to use to connect to the tenant. Default is the EUC secret.
    .EXAMPLE
    .\RenameAndroidISDs.ps1 
    .NOTES

    Makes use of the LogOutputPath environment variable for logging output. Ensure this variable is set to a valid path before running the script.

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True, HelpMessage = "The tenantId of the tenant to connect to.")]
    [string]$TenantId,
    [Parameter(Mandatory = $True, HelpMessage = "The group id of the AAD group to check for devices.")]
    [string[]]$GroupId,
    [Parameter(Mandatory = $True, HelpMessage = "The credential to use to connect to the tenant.")]
    [pscredential]$Credential
)

# Set error handling preferences - stop on errors and show information messages
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Start logging session to capture all output for audit purposes
If( -not $env:LogOutputPath ) {
    Write-Warning "LogOutputPath environment variable is not set. Logging will be saved to $env:tmp"
    $env:LogOutputPath = $env:tmp
}
Start-Transcript -Path "$env:LogOutputPath\RenameAndroidISDs.log" -Append


Function GetNamePatternForDevice {
    <#
.SYNOPSIS
    Generates the expected device name pattern based on enrollment profile and serial number.
.DESCRIPTION
    Creates a standardized device name using the format: EnrollmentProfileName-SerialNumber
    Removes "Android-" prefix from enrollment profile name for cleaner naming.
.PARAMETER device
    The device object containing SerialNumber and EnrollmentProfileName properties.
.OUTPUTS
    String containing the formatted device name pattern.
#>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Device
    )
    
    # Use conditional array indexing to handle null/empty serial numbers
    $serialNumber = @($Device.SerialNumber, $null)[[string]::IsNullOrEmpty($Device.SerialNumber)]
    Write-Verbose "Serial Number: $serialNumber"
    
    # Remove 'Android-' prefix from enrollment profile name and handle null/empty values
    $enrollmentProfileName = @($Device.EnrollmentProfileName -Replace "Android-", $null)[[string]::IsNullOrEmpty($Device.EnrollmentProfileName)]
    Write-Verbose "Enrollment Profile Name: $enrollmentProfileName"
    
    # Construct the standardized device name pattern
    $newNamePattern = "$enrollmentProfileName-$serialNumber"

    Write-Output $newNamePattern
}

Function Rename-IntuneManagedDevice {
    <#
    .SYNOPSIS
    Renames a managed device in Intune.
    .DESCRIPTION
    Renames a managed device in Intune.
    .PARAMETER Id
    The ID of the device to rename.
    .PARAMETER NewName
    The new name for the device.
    .EXAMPLE
    Rename-IntuneManagedDevice -Id "12345678-1234-1234-1234-123456789012" -NewName "NewDeviceName"
    Renames the device with the ID "12345678-1234-1234-1234-123456789012" to "NewDeviceName".
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true, Position = 0,ValueFromPipeline)]
        [ValidateScript({$_ -match "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"})]
        [string[]]$Id,
        [Parameter(Mandatory=$true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$NewName
    )

    $params = @{
        Uri     = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$Id')/setDeviceName"
        Method  = "POST"
        Body    = @{
            deviceName = $NewName
        
        }

    }
    Try{
     If ($PSCmdlet.ShouldProcess("$id","Rename device to $NewName")) {
        Invoke-MgGraphRequest @params
    }
    Write-Information "Device with ID $Id has been renamed to $NewName."
}
    Catch { 

        Write-Warning $_.Exception.Message
        Write-Error "Failed to rename device." -ErrorAction Stop
    }
}


# Connect to Microsoft Graph using client secret credentials
Connect-MgGraph -ClientSecretCredential $Credential -TenantId $TenantId -NoWelcome


# Determine execution mode based on current Git branch
# Main branch = Production mode (actual changes), Other branches = Test mode (WhatIf only)
If ($(git -C "$PSScriptRoot" branch --show-current) -eq "RealProductionMain") {
    # Production configuration - actually perform device renames
    $WhatIf = $false
}
Else {
    # Development/Test configuration - simulate changes only
    $WhatIf = $true
}

# Display current execution configuration for verification
Write-Verbose "WhatIf: $WhatIf"             -Verbose



# Initialize collections to track operation results for reporting
$failedToFind     = [System.Collections.ArrayList]::new()  # Devices not found in Intune
$failedToRename   = [System.Collections.ArrayList]::new()  # Devices that failed to rename
$successfulRename = [System.Collections.ArrayList]::new()  # Successfully renamed devices


Try {
    # Process each specified Azure AD group to find member devices
    $groupMembers = Foreach ($id in $groupId ) {
        # TODO: Implement type checking for group members if needed
        
        # Get all devices that are members of the current group (including transitive membership)
        $devices = $(Get-MgBetaGroupTransitiveMemberAsDevice -GroupId $id -All )
        
        # Process each device found in the group
        Foreach ( $device in  $devices) { 
            Try {
                # Find the managed device in Intune using the Azure AD Device ID
                $managedDeviceFromFilter = Get-MgBetaDeviceManagementManagedDevice -Filter "AzureADDeviceId eq '$($device.deviceId)'" -Select Id -ErrorAction STOP

                # Retrieve detailed device information needed for renaming
                Get-MgBetaDeviceManagementManagedDevice -ManagedDeviceId $managedDeviceFromFilter.Id -Select Id, SerialNumber, deviceName, EnrollmentProfileName, AzureADDeviceId -ErrorAction Stop
            }
            Catch {
                # Track devices that couldn't be found in Intune for later reporting
                $failedToFind.Add($device.deviceId) | Out-Null
            }
        }
    }
}
Catch { 
    # Log detailed error information and exit if group member retrieval fails
    Write-Verbose $_.Exception.Message
    Write-Error "Failed to get group members." 
    Exit 10
}

# Report any devices that couldn't be located in Intune
If ( $failedToFind.Count -gt 0 ) {
    Write-Warning "Failed to find the following device(s): $($failedToFind -join ', ')"
}

# Display total number of devices found for processing
Write-Verbose "Total Devices: $($groupMembers.Count)"   -Verbose

# Identify devices that need renaming (current name doesn't match expected pattern)
$renameMembers = $groupMembers | Where-Object { $_.deviceName -ne $($_ | GetNamePatternForDevice) }


# Process devices that require renaming
If ( $renameMembers.Count -gt 0 ) {
    Write-Verbose "Devices to rename: $($renameMembers.Count)" -Verbose
    
    # Iterate through each device that needs to be renamed
    Foreach ( $member in $renameMembers ) {
        Try {
            # Prepare parameters for the device rename operation
            $renameParams = @{
                Id                = $($member.Id)
                NewName           = $($member | GetNamePatternForDevice)
                InformationAction = 'Continue'
                WhatIf            = $WhatIf
            }
            
            # Execute the rename operation using custom function
            Rename-IntuneManagedDevice @renameParams
            
            # Add the new name to the device object for tracking
            Add-Member -InputObject $member -NotePropertyMembers @{NewName = $renameParams.NewName }
            
            # Track successful rename for reporting
            $successfulRename.Add($member) | Out-Null
        }
        Catch {
            # Log rename failures and track for reporting
            Write-Host $_.Exception.Message
            Write-Warning "Failed to rename $($member.deviceName)."
            $failedToRename.Add($member) | Out-Null
        }
    }
    
    # Send notification to Teams channel with rename operation results
#    TeamsAlert -PostAs FlowBot -PostIn Channel -TeamID $TeamID -TeamsChannelID $ChannelId -successfulRename $($successfulRename.Count) -failedToRename $($failedToRename.Count) -Title "Android ISD Rename Log"
}
Else {
    # No devices require renaming
    Write-Verbose "No devices to rename." -Verbose
}


# Stop logging session
Stop-Transcript

