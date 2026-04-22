<#
    .SYNOPSIS
    Retire non-compliant iOS devices.
    .DESCRIPTION
    Retire all non-compliant devices on the retirement list whose scheduled retirement date has passed.
    .PARAMETER tenantId
    The tenant ID to connect to.
    .PARAMETER credential
    The credential to use to connect to the tenant.
    .EXAMPLE
    RetireNonCompliantIOSDevices.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -Credential (Get-Secret -Name SuperSecret)
    .NOTES
    Ensure you have the necessary permissions to retire devices in Intune. Use with caution, as retiring devices will remove them from management and may cause data loss if  done properly.
    

#>
[CmdletBinding()]
param(
        [Parameter(Mandatory = $True, HelpMessage = "The tenantId of the tenant to connect to.")]
    [string]$TenantId,
    [Parameter(Mandatory = $True, HelpMessage = "The credential to use to connect to the tenant.")]
    [pscredential]$Credential

)
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

If( -not $env:LogOutputPath ) {
    Write-Warning "LogOutputPath environment variable is not set. Logging will be saved to $env:tmp"
    $env:LogOutputPath = $env:tmp
}

Start-Transcript -Path "$env:LogOutputPath\RetireiOSDevices.log" -Append
Try{
    Connect-MgGraph -ClientSecretCredential $Credential -TenantId $TenantId
    Write-Information "Connected to Graph API"
}
Catch {
    Write-Error "Failed to connect to Graph API"
    Break
}

#Yes I know this could be done better but here's the thing:  <Click to Read More>
If ($(git -C "$PSScriptRoot" branch --show-current) -eq "RealProductionBranchCalledMainOrWhatever") {
    $WhatIf = $false
    $Action = "retire"

}
Else {
    $WhatIf    = $true
    $Action    = "syncDevice"

}

Write-Information "WhatIf:      $WhatIf"
Write-Information "Action:      $Action"

Function Get-IntuneRetirementList{
    <#
    .SYNOPSIS
        This function will return a list of devices that are non-compliant and ready to be retired.
    .DESCRIPTION
        This function will return a list of devices that are non-compliant and ready to be retired.
    .PARAMETER Filter
        The filter to use to return the list of devices. Default is to return all non-compliant devices.
    .PARAMETER Select
        The properties to return for each device. Default is to return DeviceId, AadDeviceId, DeviceName, ComplianceState, OSDescription, OS, OwnerType, ManagementAgents, PolicyId, PolicyName, ScheduledRetireState, RetireAfterDatetime.
    .PARAMETER OrderBy
        The order to return the devices in. Default is to return the devices ordered by DeviceName in ascending order.
    .EXAMPLE
        Get-IntuneRetirementList
    .EXAMPLE
        Get-IntuneRetirementList -Filter "DeviceName eq 'TestDevice'"
    .EXAMPLE
        Get-IntuneRetirementList -Filter "DeviceName eq 'TestDevice'" -Select "DeviceId","DeviceName","ComplianceState","OSDescription","OS","OwnerType","ManagementAgents","PolicyId","PolicyName","ScheduledRetireState","RetireAfterDatetime"
    .EXAMPLE
        Get-IntuneRetirementList -Filter "DeviceName eq 'TestDevice'" -Select "DeviceId","DeviceName","ComplianceState","OSDescription","OS","OwnerType","ManagementAgents","PolicyId","PolicyName","ScheduledRetireState","RetireAfterDatetime" -OrderBy "DeviceName desc"
    #>
    
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Filter,
        [Parameter(Mandatory=$false, Position=1)]
        [array]$Select = @("DeviceId","AadDeviceId","DeviceName","ComplianceState","OSDescription","OS","OwnerType","ManagementAgents","PolicyId","PolicyName","ScheduledRetireState","RetireAfterDatetime"),
        [Parameter(Mandatory=$false, Position=1)]
        [string]$OrderBy = "DeviceName asc"
    )

    $body = @"

    {
        "top": 50,
        "skip": {{skip}},
        "select": $($Select | Convertto-JSON | Out-String),
        "orderBy": [
            "$OrderBy"
        ],
        "filter": "$Filter"
    }
"@
    $tempFile = New-TemporaryFile
    
    Invoke-MGGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/getNoncompliantDevicesToRetire" -Method POST -OutputFilePath $tempFile -Body @{top=1;skip=0;orderby=@("DeviceId asc");select=@("DeviceId");filter=$filter}
    $TotalRowCount = Get-content $tempFile | ConvertFrom-Json | Select-Object -ExpandProperty TotalRowCount

    $skipBatches = $(0..$totalRowCount | Where-Object {$_ % 50 -eq 0}) | ForEach-Object {
        [PSCustomObject]@{
            skip = $_[0]
        }
    } | Get-BatchArray -BatchSize 20
    
    $requestGroups = $($skipBatches) | ForEach-Object {
        New-GraphBatchBody -Uri "/deviceManagement/deviceCompliancePolicies/getNoncompliantDevicesToRetire" -Method POST -Body $body -InputObject $_
    }

    $resp = Foreach( $request in $requestGroups ){
        Invoke-mggraphrequest -uri 'https://graph.microsoft.com/beta/$batch' -Method POST -Body $($request|convertto-json -depth 10)
        }
        $list = $resp.responses.body | Foreach-Object{$_|ConvertFrom-Base64|ConvertFrom-SchemaValueSet}
        Write-Output $list

}

Function Invoke-IntuneDeviceAction {
    <#
    .SYNOPSIS
        This function will create a Graph API batch request to perform an action on a list of devices.
    .DESCRIPTION
        This function will create a Graph API batch request to perform an action on a list of devices.
    .PARAMETER InputData
        The array of objects to use to create the Graph API batch request.
        This must be one or more Device Ids in the format of a GUID.
    .PARAMETER Action
        The action to take on the device. Valid values are 'syncDevice' and 'retire'. Default is 'syncDevice'.
    .EXAMPLE
        Invoke-IntuneDeviceAction -InputData $Id -Action 'syncDevice'

    #>
    [cmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0, HelpMessage = "The array of objects use to create the Graph API batch request")]
        [ValidateScript({ $_ -match '^([0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})$' })]
        [Alias('Id', 'DeviceId','Device ID')]
        [string[]]$Device,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The action to take on the device. Valid values are 'syncDevice' and 'retire'. Default is 'syncDevice'")]
        [ValidateSet('syncDevice', 'retire', 'wipe','rebootNow')]
        [string]$Action = 'syncDevice'
    )
    Begin {

        $headers = @{
            'Content-Type' = "application/json"
        }
        $batchBody = @{
            "requests" = @()
        }
        $id = 0
    }
    Process {
        If ($Device.count -gt 20) {
            Write-Error -Message "The maximum number of devices that can be actioned in a single run is 20. Please reduce the number of devices and try again."
            
        }
        Foreach ($item in $Device) {
            $batchBody.requests += @{
                "id"      = $id
                "method"  = "POST"
                "url"     = "/deviceManagement/managedDevices/$item/$Action"
                "body"    = @{}
                "headers" = @{ 'Content-Type' = "application/json" }
            }
            $id++
            Write-Information -MessageData "Adding $item to Batch request to $Action device."
        }
    
        
    
    }
    End {
        Try{
            $batchBody.Requests | Foreach-Object {
            $deviceId = ((($_.url) -Split '/')[-2])
            Write-Information -MessageData "$Action Device $deviceId"
        }
        }
        Catch{
            Write-Information -Message "Error while getting device id."
            Write-Host $batchBody.Requests
        }
        
        If ($PSCmdlet.ShouldProcess("$($batchBody.Requests.count) devices", "$action")) {
            $mgResponse = Invoke-MGGraphRequest -Method 'POST' -Uri 'https://graph.microsoft.com/beta/$batch' -Body $batchBody -Headers $headers
        }
    
        Foreach ($response in $mgResponse.responses) {
            $respDeviceId = ((([pscustomobject]($batchBody.requests | Where-Object id -eq $response.id) | Select-Object -ExpandProperty url ) -Split '/')[-2])
            If ($response.status -eq 204) {
                Write-Information -MessageData "$Action successful for device $respDeviceId."
            }
            Else {
                Write-Error -Message "$Action failed for device $respDeviceId with status code $($response.status)"
                Write-Information -MessageData $($response | Convertto-Json -depth 5)
            }
        }
    }

}

Try {
    $retireMembers = Get-IntuneRetirementList | Where-Object { 
                                                    $_.OS               -eq "iOS"       -AND 
                                                    $_.ComplianceState  -eq 2           -AND 
                                                    $_.RetireAfterDate  -lt (Get-Date) 
                                                }

    
    Write-Information "Retire Members Count: $(($retireMembers| Measure-Object).Count)" -InformationAction Continue
}
Catch { Write-Error "Failed to get retirement list." }


$failedToRetire   = [System.Collections.ArrayList]::new()
$successfulRetire = [System.Collections.ArrayList]::new()


$retireMembersBatch = $retireMembers | Get-BatchArray -BatchSize 20

If ( $retireMembers.Count -lt 1 ) {
    Write-Information "No devices to retire." -InformationAction Continue
}
Else {
    $date = Get-Date -Format "yyyy-MM-dd"
    Write-Information "Retiring devices..." -InformationAction Continue
    $i = 1
    Foreach ($batch in $retireMembersBatch) {
        Write-Information "Batch $i of $($retireMembersBatch.Count)" -InformationAction Continue
        $i++
        Try {
            #!! Danger Zone
            Invoke-IntuneDeviceAction -Action $Action -Device $batch.deviceId -InformationAction Continue -WhatIf:$WhatIf
            Write-Information "Retiring devices: $($batch.deviceId)" -InformationAction Continue
            #/!!
            Write-Information "Devices retired." -InformationAction Continue
        }
        Catch {
            Write-Warning "Failed to retire devices: $_"
        }
    }
    Start-Sleep -Seconds 5

    $auditParams = @{
        Filter = "Category eq 'Device' and ActivityType eq '$Action ManagedDevice' and ActivityDateTime ge $date and ActivityResult eq 'Success'"
    }
    
    $auditEvents = Get-MgBetaDeviceManagementAuditEvent @auditParams

    
    $successfulRetire = $retireMembers | Where-Object { $_.deviceId -in $($auditEvents | select-object -expand resources).ResourceId }
    Write-Information "Retired Devices Count: $(($successfulRetire| Measure-Object).Count)"
    
    $failedToRetire = $retireMembers | Where-Object { $_.deviceId -notin $successfulRetire.deviceId }
    Write-Information "Failed to Retire Devices Count: $(($failedToRetire| Measure-Object).Count)"
    Write-Information "Failed to Retire Devices: `n$($failedToRetire.deviceId)" -InformationAction Continue

    Try{
        Write-Information "Posting results to Teams..." -InformationAction Continue
        #Here's where I would post to teams but thats another script for another talk.
        
        #TeamsAlert -PostAs FlowBot -PostIn Channel -TeamID $TeamId -TeamsChannelID $TeamsChannelID -successfulRetire $($successfulRetire.Count) -failedToRetire $($failedToRetire.Count) -Title "iOS Retire Log"
    }
    Catch {
        Write-Error "Failed to post results to Teams: $_"
    }

}


Stop-Transcript

