Function ConvertTo-HashTableFromColumnsAndValues {
    param(
        $inputData
    )
    
    Foreach ($entry in $inputdata.Values) {
        New-Variable -Name hash -Value (New-Object -TypeName PSObject)
        for ($i = 0; $i -lt $inputdata.schema.count; $i++) {

            Add-Member -InputObject $hash -NotePropertyMembers @{"$(($inputdata.Schema[$i]).column)" = "$($entry[$i])" }


        }
        $hash
        Remove-Variable -Name hash
    }
}

Function ConvertFrom-Base64 {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The base64 encoded string to decode")]
        [string]$base64
    )
    Write-Output $([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64)))
}

Function New-ReadinessReport {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "The report name")]
        [ValidateSet("MEMUpgradeReadinessDevice", "MEMUpgradeReadinessOrgAppAndDriverV2")]
        [string]$reportName = "MEMUpgradeReadinessDevice",
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The format of the report")]
        [ValidateSet("json", "csv")]
        [string]$Format = "json",
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The Target OS String (eg NI22H2)")]
        [string]$TargetOS = "NI23H2"
    )
    


    $body = @{
        reportName = $reportName
        filter     = "(TargetOS eq '$TargetOS')"
        format     = $Format
    }
    If ($reportName -ne "MEMUpgradeReadinessOrgAppAndDriverV2") {
        $body.filter = $body.filter + " and (DeviceScopesTag eq '00011')"
    }
    $resp = Invoke-MGGraphRequest -uri "https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs" -method POST -Body $body -OutputType PSObject
    Write-Output $resp
}


Function Receive-ReadinessReport {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0, HelpMessage = "The Id of the report to download")]
        [string]$id,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The path to save the report to")]
        [string]$outfilePath,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The name of the file to save the report to")]
        [string]$outfileName = "$id--$(Get-Date -Format "yyyyMMddHHmmss").zip",
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, Position = 3, HelpMessage = "The format of the report")]
        [string]$Format = "json"
    )
    Try {
        $url = $(Invoke-MGGraphRequest -uri "beta/devicemanagement/reports/exportJobs('$id')").url
    }
    Catch { Write-Error -Message "Error Retrieving Report URL: $_" }
    $elapsed = 0
    $count = 10
    $downloadedReportZip = $(Join-Path $outfilePath $outfileName)
    While ($null -eq $url -AND $elapsed -lt $count * 4) {
            
        Write-Information -MessageData "URL is NULL, Download is Not Yet Ready. Retrying in $count seconds..."
        Start-Sleep -Seconds $count
        $elapsed += $count
        $url = $(Invoke-MGGraphRequest -uri "beta/devicemanagement/reports/exportJobs('$id')").url

    }

    Write-Information -MessageData "URL Found, Downloading From $url"

    Try {
        $downloadReq = Invoke-WebRequest -Uri $url -OutFile $downloadedReportZip
        Write-Information -MessageData "Download Complete"
    }
    Catch { Write-Error -Message "Error Downloading Report: $_" }
    
    Try {
        Write-Information -MessageData "Expanding Report"
        $jobExpandReport = Start-Job -Name "ExpandReport" -ScriptBlock {
            param(
                $downloadedReportZip
            )
            Expand-Archive -Path $downloadedReportZip -DestinationPath (Split-Path $downloadedReportZip)
        } -ArgumentList $downloadedReportZip 
    
        Wait-Job -id $jobExpandReport.id | Out-Null
        Write-Information -MessageData "Report Expanded at $(Split-Path $downloadedReportZip)\$id.$format"
    }
    Catch { Write-Error -Message "Error Expanding Report: $_" }

    Try {
        Write-Information -MessageData "Getting Report Data"
        $ReportInformation = $(Get-Content -Path "$(Split-Path $downloadedReportZip)\$id.$Format")
        Write-Output $ReportInformation
    }
    Catch { Write-Error -Message "Error Reading Report Data: $_" }
}

Function Get-BatchArray {
    <#
        .SYNOPSIS
            This function will split an array of objects into batches of a specified size.
        .DESCRIPTION
            This function will split an array of objects into batches of a specified size.
        .PARAMETER ObjectArray
            The array of objects to split into batches.
        .PARAMETER BatchSize
            The size of the batches.
        .EXAMPLE
            Get-BatchArray -ObjectArray $Id -BatchSize 20
        #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The array of objects to split into batches")]
        [Object[]]$ObjectArray,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The size of the batches")]
        [int]$BatchSize
    )
    Begin {
        $batcharray = New-Object -TypeName System.Collections.ArrayList
        $batch = New-Object -TypeName System.Collections.ArrayList
        $i = 0
    }
    Process {
        Foreach ($object in $ObjectArray) {
            $batch.Add($object) | out-Null
            $i++
            If ($i -eq $BatchSize) {
                $batchArray.Add($batch[0..($batch.count - 1)]) | Out-Null
                $batch = New-Object -TypeName System.Collections.ArrayList
                $i = 0
            }
        }
    }
    End {
        If ($batch.count -gt 0) {
            $batchArray.Add($batch[0..($batch.count - 1)]) | Out-Null
        }
        Write-Output @(, $batchArray)
    }
}


Function Get-BatchStartEnd {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Total,
        [Parameter(Mandatory = $true)]
        [int]$BatchSize
    )
    $batchStartEnd = New-Object System.Collections.ArrayList
    $batchStart = 0
    $batchEnd = 0
    $remainder = 0
    $batchCount = [System.Math]::DivRem($Total, $BatchSize, [ref]$remainder)
    If ($batchCount -gt 0) {
        For ($i = 1; $i -le $batchCount; $i++) {
            $batchStart = $($i * $BatchSize) - $BatchSize
            $batchEnd = $($i * $BatchSize) - 1
            $batchStartEnd.Add(@($batchStart, $batchEnd)) | out-null
        }
    }
    If ($remainder -gt 0) {
        $batchStart = $($Total - $remainder)
        $batchEnd = ($Total - 1)
        $batchStartEnd.Add(@($batchStart, $batchEnd)) | out-null
    }
    Write-Output @(, $batchStartEnd)
}

Function New-IssueRequestBatch {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The array of objects use to create the Graph API batch request")]
        [array[]]$InputData,
        [parameter(Mandatory = $false, Position = 1, HelpMessage = "The target OS to filter the report on")]
        $TargetOS = "NI23H2",
        [parameter(Mandatory = $true, Position = 2)]
        $AssetType
    )
    Switch ($assetType) {
        "Driver" {
            $reportName = "MEMUpgradeReadinessOprDriverAsset"
        }
        "Application" {
            $reportName = "MEMUpgradeReadinessOprApplicationAsset"
        }
        "Other" {
            $reportName = "MEMUpgradeReadinessOprOtherApplicationAsset"
        }
        Default {
            Write-Error -Message "Invalid Asset Type: $assetType"
        }
    }

    $batchBody = @{
        "requests" = @()
    }
    $id = 0
    Foreach ($device in $InputData) {
        $batchBody.requests += @{
            "id"     = $id
            "method" = "POST"
            "url"    = "/deviceManagement/reports/getReportFilters"
            "body"   = @{
                name    = $reportName
                top     = 40
                select  = @(
                    'DeviceId',               
                    'AadDeviceId',       
                    'AssetType',              
                    'AssetId',                
                    'AssetName',              
                    'AssetVendor',            
                    'AssetVersion',           
                    'TargetOS')
                skip    = 0
                filter  = "(TargetOS eq '$targetOS') and (DeviceId eq '$($device.deviceId)')"
                orderBy = @("DeviceName desc")
                
            }
            headers  = @{'Content-Type' = "application/json" }
        }
        $id++
    }

    $retryCount = 0
    Do {
        $resp = Invoke-MgGraphRequest -URI 'https://graph.microsoft.com/beta/$batch' -Method Post -Body $batchBody 
        Write-Information -MessageData $($resp.Responses | Select-Object id, status)
        If ($resp.responses.status -eq 500) {
                    
            Write-Information -MessageData "500 Error, $retryCount retry attempts, retrying in 70 seconds..."
            Start-Sleep -Seconds 70
            $resp = Invoke-MgGraphRequest -URI 'https://graph.microsoft.com/beta/$batch' -Method Post -Body $batchBody 
            $retryCount++
            Write-Information -MessageData $($resp.Responses | Select-Object id, status)
        }
    }
    While ($resp.responses.status -eq 500 -AND $retryCount -lt 10)
    $resp.responses | Foreach-Object {
        $converted = ConvertFrom-Base64($_.body) | ConvertFrom-JSON
        Write-Output $(ConvertTo-HashTableFromColumnsAndValues -inputData $(ConvertFrom-Base64($_.body) | ConvertFrom-JSON) )
    }
    
    

}
Function Invoke-ReadinessReportBatchRequest {
    param(
        [psobject]$body
    )

    $resp = Invoke-MGGraphRequest -uri "https://graph.microsoft.com/beta/`$batch" -method POST -Body $body
    $output = @{
        FailedResponses    = $resp.Responses | Where-Object status -ne 200
        SucceededResponses = $resp.Responses | Where-Object status -eq 200
    }
    Write-Output $output

}

Function Get-ReadinessRisksByDevice {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName, HelpMessage = "The total number of issues for the asset")]
        [Alias("DeviceIssuesCount")]
        $Total,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The batch size to use for the Graph API batch request")]
        $BatchSize,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, HelpMessage = "The asset data to use for the Graph API batch request")]
        $AssetData,
        [Parameter(Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName, HelpMessage = "The target OS to filter the report on")]
        $TargetOS
    )
    $objArrays = $(Get-BatchArray -BatchSize 20 -ObjectArray $(Get-BatchStartEnd -Total $Total -BatchSize $BatchSize))
    $objArrays | ForEach-Object -Begin { $i = 0 } -Process {
        $i++
        $batchBody = @{
            "requests" = @()
        }
        
        Foreach ($array in $_) {
            $batchStart = $array[0]
            $batchEnd = $array[1]
            
            $id = $batchStart
            $batchBody.requests += @{
                "id"     = $id
                "method" = "POST"
                "url"    = "/deviceManagement/reports/getReportFilters"
                "body"   = @{
                    name   = "MEMUpgradeReadinessOprDevicesPerAsset"
                    top    = $batchSize
                    select = ""
                    skip   = $batchStart
                    filter = "(TargetOS eq '$targetOS') and (AssetType eq '$($assetData.AssetType)') and (AssetName eq '$($assetData.AssetName)') and (AssetVendor eq '$($assetData.AssetVendor)') and (AssetVersion eq '$($assetData.AssetVersion)')"
                    
                }
                headers  = @{
                    'Content-Type'           = "application/json"
                    'x-ms-throttle-priority' = 'high'
                }
            }
            
            #Write-Information -MessageData "Inner Batch Id: $id"
            If ($batchEnd -lt $batchSize - 1) { Break }

        }
        Write-Information -MessageData "Outer Batch Number: $i"
        $retryCount = 0
        $retryBody = @{"requests" = @() }

       
        $responses = Invoke-ReadinessReportBatchRequest -body $batchBody
        $failedResp = $responses.FailedResponses
        $succeededResp = $responses.SucceededResponses
        Write-Information -MessageData "Failed: $(      $failedResp     | Measure-object | select -expand count)"
        Write-Information -MessageData "Succeeded: $(   $succeededResp  | Measure-object | select -expand count)"

        If ($null -ne $succeededResp) {
            $succeededResp | ForEach-Object { Write-Output $(ConvertTo-HashTableFromColumnsAndValues -inputData $(ConvertFrom-Base64($_.body) | ConvertFrom-JSON) ) }
            $succeededResp = $null

        }
        
        While ($retryCount -lt 10 -AND ($null -ne $failedResp) ) {

            If ( $failedResp.Status -contains 500 ) {

                Write-Information -MessageData "500 Error, $retryCount retry attempts, retrying in 70 seconds..."
                Start-Sleep -Seconds 70
            }

            $maxRetryvalue = [int]$($failedResp | Select-Object -ExpandProperty headers | Sort-Object "Retry-After" -Desc | Select-Object -ExpandProperty "Retry-After" -First 1 -ErrorAction SilentlyContinue)
            
            [int]$retryInterval = ([int]$maxRetryvalue + 8)


            Write-Information -MessageData $($failedResp | Select-Object id, status, @{N = 'Retry-After'; E = { $_.headers.'Retry-After' } }|out-string)
            Write-Information -MessageData "429 Error, $retryCount retry attempts, retrying in $retryInterval seconds..."
            Start-Sleep -Seconds $retryInterval
                
            $retryBody = @{"requests" = @() }

            foreach ($item in $failedResp ) {
                $retryBody.requests += @{
                    "id"     = $item.id
                    "method" = "POST"
                    "url"    = "/deviceManagement/reports/getReportFilters"
                    "body"   = @{
                        name   = "MEMUpgradeReadinessOprDevicesPerAsset"
                        top    = $BatchSize
                        select = ""
                        skip   = $item.id
                        filter = "(TargetOS eq '$targetOS') and (AssetType eq '$($assetData.AssetType)') and (AssetName eq '$($assetData.AssetName)') and (AssetVendor eq '$($assetData.AssetVendor)') and (AssetVersion eq '$($assetData.AssetVersion)')"
                                                
                    }
                    headers  = @{
                        'Content-Type'           = "application/json"
                        'x-ms-throttle-priority' = 'high'
                    }
                }
            }
            $responses = Invoke-ReadinessReportBatchRequest -body $retryBody
            $failedResp = $responses.FailedResponses
            $succeededResp = $responses.SucceededResponses        

            If ($null -ne $succeededResp) {
                $succeededResp | ForEach-Object { Write-Output $(ConvertTo-HashTableFromColumnsAndValues -inputData $(ConvertFrom-Base64($_.body) | ConvertFrom-JSON) ) }
                $succeededResp = $null
    
            }

                
            Write-Information -MessageData "Failed: $(      $failedResp     | Measure-object | select -expand count)"
            Write-Information -MessageData "Succeeded: $(   $succeededResp  | Measure-object | select -expand count)"
            $retryCount++
        }
        If ($null -ne $succeededResp) {
            $succeededResp | ForEach-Object { Write-Output $(ConvertTo-HashTableFromColumnsAndValues -inputData $(ConvertFrom-Base64($_.body) | ConvertFrom-JSON) ) }
            $succeededResp = $null
    
        }
        If ($null -ne $failedResp) {
            Write-Warning -Message "These Requests Still Failed After $retryCount attempts: $_"
        }
    }
            
            
}
        

Function Get-ReadinessRiskUpdateValueQuery {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$TableName,
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $true)]
        [string]$InstanceName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$tabledata,
        [Parameter(Mandatory = $false)]
        [object[]]$WhereColumns = @("TargetOS", "AssetType", "AssetName", "AssetVendor", "AssetVersion")
    )

    Process {
        $columnsQuery = @"
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = '$TableName'
"@
        $updateQuery = @"
    UPDATE $TableName 
    SET
"@
        $tableColumnsParams = @{
            ServerInstance         = $InstanceName
            Database               = $DatabaseName
            Query                  = $columnsQuery
            ConnectionTimeout      = 600
            TrustServerCertificate = $true
        }
        $tableColumns = Invoke-Sqlcmd @tableColumnsParams | Select-Object -ExpandProperty COLUMN_NAME
        $updateColumns = $tableColumns | Where-Object { $WhereColumns -notcontains $_ }
        $first = $true
    
        Foreach ($column in $updateColumns) {
        
            $updateQueryLineString = ", $column = '$($tableData.$column)' "

            If ($first -eq $true) { $updateQueryLineString = $updateQueryLineString.SubString(1) }
        
            $updateQuery += $updateQueryLineString
            $first = $false

        }
        $updateQuery += "WHERE "
        $first = $true
        Foreach ($column in $WhereColumns) {
            $updateQueryLineString = " AND $column = '$($tableData.$column)'"
            If ($first -eq $true) { $updateQueryLineString = $updateQueryLineString.SubString(4) }
            $updateQuery += $updateQueryLineString
            $first = $false
        }

        Write-Output $updateQuery
    }
}
Function Get-ReadinessRiskToZeroQuery {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$TableName,
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $true)]
        [string]$InstanceName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$tableData,
        [Parameter(Mandatory = $false)]
        [object[]]$WhereColumns = @("TargetOS", "AssetType", "AssetName", "AssetVendor", "AssetVersion")
    )

    Process {
        Foreach ($entry in $tableData) {
            $updateToZeroQuery = @"
            UPDATE $TableName 
            Set DeviceIssuesCount  = 0 
"@    

            $updateToZeroQuery += "WHERE "
            $first = $true
            Foreach ($column in $WhereColumns) {
                $updateQueryLineString = " AND $column = '$($tableData.$column)'"
                If ($first -eq $true) { $updateQueryLineString = $updateQueryLineString.SubString(4) }
                $updateToZeroQuery += $updateQueryLineString
                $first = $false
            }

            Write-Output $updateToZeroQuery
        }
    }
}
Function Get-ReadinessReportTargetOSList {
    <#
    .SYNOPSIS
        This function will return a list of target OS's from the MEMUpgradeReadinessTargetOS report.
    .DESCRIPTION
        This function will return a list of target OS's from the MEMUpgradeReadinessTargetOS report.
    .EXAMPLE
        Get-ReadinessReportTargetOSList
        This will return a list of target OS's from the MEMUpgradeReadinessTargetOS report.

    #>
    $tempFile = New-TemporaryFile

    $params = @{
        Uri            = "https://graph.microsoft.com/beta/deviceManagement/reports/getReportFilters"
        Method         = "POST"
        Body           = @{
            name    = "MEMUpgradeReadinessTargetOS"
            select  = $null
            skip    = 0
            top     = 100
            filter  = ""
            orderBy = @("DisplayName desc")
        }
        OutputFilePath = $tempFile
        OutputType     = "PSObject"
    }

    Write-Verbose "Getting Target OS List"

    Try {
        $resp = Invoke-MgGraphRequest @params -ProgressAction SilentlyContinue
        Write-Verbose "Target OS List Received"
    }
    Catch {
        Write-Verbose $resp
        Write-Error -Message "Error Getting Target OS List: $_"

    }
    Try {
        $filterList = Get-Content $tempfile | ConvertFrom-SchemaValueSet
    }
    Catch {
        Write-Error -Message "Error Converting Target OS List: $_"
    }
    Write-Output $filterList
}

Function Get-ReadinessIssueUpdateValueQuery {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$TableName,
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $true)]
        [string]$InstanceName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$tabledata,
        [Parameter(Mandatory = $false)]
        [object[]]$WhereColumns = @("AadTenantId", "DeviceId", "AadDeviceId", "TargetOS")
    )
    Begin {
        $columnsQuery = @"
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = '$TableName'
"@
        $tableColumnsParams = @{
            ServerInstance         = $InstanceName
            Database               = $DatabaseName
            Query                  = $columnsQuery
            ConnectionTimeout      = 600
            TrustServerCertificate = $true
        }
        $tableColumns = Invoke-Sqlcmd @tableColumnsParams | Select-Object -ExpandProperty COLUMN_NAME

        $updateColumns = $tableColumns | Where-Object { $WhereColumns -notcontains $_ }
    }

    Process {
        Foreach ($entry in $tableData) {
            
            $updateQuery = @"
    UPDATE $TableName 
    SET
"@
   
    
            $first = $true

            Foreach ($column in $updateColumns) {
        
                $updateQueryLineString = ", $column = '$($entry.$column)' "

                If ($first -eq $true) { $updateQueryLineString = $updateQueryLineString.SubString(1) }
        
                $updateQuery += $updateQueryLineString
                $first = $false

            }
            $updateQuery += "WHERE "
            $first = $true
            Foreach ($column in $WhereColumns) {
                $updateQueryLineString = " AND $column = '$($entry.$column)'"
                If ($first -eq $true) { $updateQueryLineString = $updateQueryLineString.SubString(4) }
                $updateQuery += $updateQueryLineString
                $first = $false
            }

            Write-Output $updateQuery
        }
    }
}