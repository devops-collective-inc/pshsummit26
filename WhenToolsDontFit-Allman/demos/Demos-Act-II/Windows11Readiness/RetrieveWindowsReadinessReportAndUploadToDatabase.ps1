<#
.SYNOPSIS
Script to retrieve Windows Readiness Report and upload it to a database.

.DESCRIPTION
This script retrieves the Windows Readiness Report and uploads it to a specified SQL database. It connects to the Microsoft Graph API to fetch the report data and uses SQL Server to store the data in the database. The script generates three reports: Status Report, Risk Report, and Issues Report.

.PARAMETER Credential
PSCredential object containing the Service Principal Client Secret and App ID. 

.PARAMETER sqlInstance
The SQL Instance to connect to. This parameter defaults to "localhost\SQLEXPRESS".

.PARAMETER sqlDatabase
The SQL Database to connect to.

.PARAMETER TargetOS
The target OS to filter the report on. This parameter defaults to "NI23H2".

.EXAMPLE
RetrieveWindowsReadinessReportAndUploadToDatabase.ps1 -Credential $credential -sqlInstance "localhost\SQLEXPRESS" -sqlDatabase "reporting" -TargetOS "NI23H2"

This example runs the script with the specified parameters.

.NOTES
- This script requires the Microsoft.Graph.Authentication and SqlServer modules to be imported.
- The script connects to the Microsoft Graph API using the provided credentials.
- The script retrieves the Windows Readiness Status Report, Risk Report, and Issues Report.
- The reports are exported to CSV files and saved in the specified temporary directory.
- The script truncates the staging tables in the database and inserts the report data into the corresponding tables.
- The script performs comparisons between the current data in the database and the new report data to identify new risks, missing risks, and updated risks.
- The script updates the WindowsUpgradeReadinessRisks table with new risks, updates the deviceIssuesCount to zero for missing risks, and updates the values for existing risks.
- The script retrieves the Windows Readiness Risk Data Device Report and inserts it into the WindowsUpgradeReadinessIssues_LOAD table.
- The script selects entries from the issues table where the device ID is in the status with a readiness status of 4 and the target OS matches the specified value.
- The script inserts entries into the issues_load table with a readiness status of 255 (upgraded).
- The script truncates the WindowsUpgradeReadinessIssues table and copies the data from the issues_load table.

#>

<#
.SYNOPSIS
Script to retrieve Windows Readiness Report and upload it to a database.

.DESCRIPTION
This script retrieves the Windows Readiness Report and uploads it to a specified SQL database. It connects to the Microsoft Graph API to fetch the report data and uses SQL Server to store the data in the database. The script generates three reports: Status Report, Risk Report, and Issues Report.

.PARAMETER Credential
PSCredential object containing the Service Principal Client Secret and App ID. This parameter defaults to the secret stored as "SuperSecret" in the secret vault.

.PARAMETER sqlInstance
The SQL Instance to connect to. This parameter defaults to "localhost\SQLEXPRESS".

.PARAMETER sqlDatabase
The SQL Database to connect to.

.PARAMETER TargetOS
The target OS to filter the report on. This parameter defaults to "NI23H2".

.EXAMPLE
RetrieveWindowsReadinessReportAndUploadToDatabase.ps1 -Credential $credential -sqlInstance "localhost\SQLEXPRESS" -sqlDatabase "reporting" -TargetOS "NI23H2"

This example runs the script with the specified parameters.

.NOTES
- This script requires the Microsoft.Graph.Authentication and SqlServer modules to be imported.
- The script connects to the Microsoft Graph API using the provided credentials.
- The script retrieves the Windows Readiness Status Report, Risk Report, and Issues Report.
- The reports are exported to CSV files and saved in the specified temporary directory.
- The script truncates the staging tables in the database and inserts the report data into the corresponding tables.
- The script performs comparisons between the current data in the database and the new report data to identify new risks, missing risks, and updated risks.
- The script updates the WindowsUpgradeReadinessRisks table with new risks, updates the deviceIssuesCount to zero for missing risks, and updates the values for existing risks.
- The script retrieves the Windows Readiness Risk Data Device Report and inserts it into the WindowsUpgradeReadinessIssues_LOAD table.
- The script selects entries from the issues table where the device ID is in the status with a readiness status of 4 and the target OS matches the specified value.
- The script inserts entries into the issues_load table with a readiness status of 255 (upgraded).
- The script truncates the WindowsUpgradeReadinessIssues table and copies the data from the issues_load table.

#>

param(
    [Parameter(Mandatory = $false, Position = 0, HelpMessage = "PSCredential object containing the Service Principal Client Secret and App ID")]
    [PSCredential]$Credential = $(Get-Secret SuperSecret),
    [parameter(Mandatory = $false, Position = 1, HelpMessage = "The SQL Instance to connect to")]
    [string]$sqlInstance = "localhost\SQLEXPRESS",
    [parameter(Mandatory = $false, Position = 2, HelpMessage = "The SQL Database to connect to")]
    [string]$sqlDatabase = "reporting",
    [parameter(Mandatory = $false, Position = 3, HelpMessage = "The target OS to filter the report on")]
    [string]$TargetOS = "NI23H2",
    [Parameter(Mandatory = $True, HelpMessage = "The tenantId of the tenant to connect to.")]
    [string]$TenantId
)
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$startTime = Get-Date
[string]$date = $(Get-Date -Format "yyyyMMddHHmmss")
Start-Transcript -Path "$env:LogOutputPath\windowsReadinessReport.log" -Append

Write-Information -MessageData "Date: $date"
Write-Information -MessageData "Target OS: $targetOS"
Write-Information -MessageData "SQL Instance: $sqlInstance"
Write-Information -MessageData "SQL Database: $sqlDatabase"
Write-Information -MessageData "Starting Windows Readiness Report Script"


Write-Information -MessageData "Importing Modules"
Write-Information -MessageData "    Importing Microsoft.Graph.Authentication"
Import-Module -Name Microsoft.Graph.Authentication

Write-Information -MessageData "    Importing WindowsReadinessReports"
Import-Module -FullyQualifiedName $psscriptroot\WindowsReadinessReports\WindowsReadinessReports.psd1

Write-Information -MessageData "    Importing SqlServer"
Import-Module -FullyQualifiedName SqlServer

Try {
    Write-Information -MessageData "Connecting to Graph"
    Connect-MgGraph -ClientSecretCredential $Credential -TenantId $TenantId -NoWelcome -ErrorAction Stop
}
Catch {
    Write-Information -MessageData "Failed to connect to Graph"
    Write-Information $error[0]
}





#
# Status Report
#

Write-Information -MessageData "Getting Windows Readiness Status Report"
$readinessStatusReportData = New-ReadinessReport -ReportName "MEMUpgradeReadinessDevice" | Receive-ReadinessReport -outfilePath $env:TMP -InformationVariable readinessStatusLog -InformationAction Continue 
$readinessStatusReportData = $readinessStatusReportData | ConvertFrom-Json | Select-Object -ExpandProperty values | Select-Object -Property * -ExcludeProperty SchemaVersion, RowCountInSnapshot

Write-Information -MessageData "Exporting Windows Readiness Status Report to CSV at $env:tmp\readinessStatusReportData--$date.csv"
$readinessStatusReportData | Export-CSV -Path "$env:tmp\readinessStatusReportData--$date.csv" -NoTypeInformation

Write-Information -MessageData "Status Report Log saved: $env:tmp\readinessStatusLog--$date.txt"
$readinessStatusLog         | Foreach-Object { $_ | Select-Object -Property * } | Out-String | Out-File -FilePath "$env:tmp\readinessStatusLog--$date.txt"

Write-Information -MessageData "Truncating WindowsUpgradeReadinessStatus_LOAD" 
Invoke-Sqlcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query "TRUNCATE TABLE dbo.WindowsUpgradeReadinessStatus_LOAD"  -TrustServerCertificate


Try {
    Write-Information -MessageData "Writing data to WindowsUpgradeReadinessStatus_LOAD"
    Write-SqlTableData -ServerInstance $sqlInstance -DatabaseName $sqlDatabase  -SchemaName dbo -TableName WindowsUpgradeReadinessStatus_LOAD -InputData $readinessStatusReportData -Force -Timeout 600  -TrustServerCertificate -Verbose
    Write-Information -MessageData "Success"

}
Catch {
    Write-Error  "Failed to write data to staging tables"
    Write-Information -MessageData $Error[0]
}
    
$truncateTableCopyLoadSQL = @"
    TRUNCATE TABLE WindowsUpgradeReadinessStatus
    INSERT INTO WindowsUpgradeReadinessStatus
    SELECT * FROM WindowsUpgradeReadinessStatus_LOAD;
"@
Write-Information -MessageData "Truncating WindowsUpgradeReadinessStatus and copying data from WindowsUpgradeReadinessStatus_LOAD"
Try{
    Invoke-Sqlcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query $truncateTableCopyLoadSQL  -TrustServerCertificate
    Write-Information -MessageData "Success"
}
Catch {
    Write-Error  "Failed to copy data from WindowsUpgradeReadinessStatus_LOAD to WindowsUpgradeReadinessStatus"
    Write-Information -MessageData $Error[0]
}





#
# Risk Report
#

Write-Information -MessageData "Getting Windows Readiness Risk Data Report"
$readinessRiskData = New-ReadinessReport -ReportName "MEMUpgradeReadinessOrgAppAndDriverV2"    |
    Receive-ReadinessReport -outfilePath $env:TMP -InformationVariable readinessRiskLog -InformationAction Continue |
    ConvertFrom-Json |
    Select-Object -ExpandProperty values |
    Select-Object -Property * -ExcludeProperty SchemaVersion, RowCountInSnapshot

Write-Information -MessageData "Exporting Windows Readiness Risk Data Report to CSV at $env:tmp\readinessRiskData--$date.csv"
$readinessRiskData | Export-CSV -Path "$env:tmp\readinessRiskData--$date.csv" -NoTypeInformation 

Write-Information -MessageData "Risk Report Log saved: $env:tmp\readinessRiskLog--$date.txt"
$readinessRiskLog           | Foreach-Object { $_ | Select-Object -Property * } | Out-String | Out-File -FilePath "$env:tmp\readinessRiskLog--$date.txt"

$currentReadinessRisksTable         = Read-SqlTableData -ServerInstance $sqlInstance -DatabaseName $sqlDatabase -SchemaName dbo -TableName WindowsUpgradeReadinessRisks  -TrustServerCertificate | Where-Object TargetOS -eq $targetOS

$riskComparisonData                 = Compare-Object -ReferenceObject $currentReadinessRisksTable       -DifferenceObject $readinessRiskData -Property AssetType, AssetName, AssetVendor, AssetVersion, TargetOS, ReadinessStatus, IssueTypes, DeviceIssuesCount | Group-Object AsseType, AssetName, AssetVendor, AssetVersion, TargetOS

Write-Information -MessageData "$($riskComparisonData|Out-String)"

#Update to Zero
$missingRisks   = $riskComparisonData | Where-Object count -eq 1 | Select-Object -exp group | Where-Object SideIndicator -eq "<=" | Where-Object TargetOS -eq $TargetOS | Select-Object -Property AssetType, AssetName, AssetVendor, AssetVersion, TargetOS, ReadinessStatus, IssueTypes, DeviceIssuesCount 
#new
$newRisks       = $riskComparisonData | Where-Object count -eq 1 | Select-Object -exp group | Where-Object SideIndicator -eq "=>" | Select-Object -Property AssetType, AssetName, AssetVendor, AssetVersion, TargetOS, ReadinessStatus, IssueTypes, DeviceIssuesCount
#Update values
$updateRisks    = $riskComparisonData | Where-Object count -eq 2 | Select-Object -ExpandProperty Group | Where-Object SideIndicator -eq '=>' | Select-Object -Property AssetType, AssetName, AssetVendor, AssetVersion, TargetOS, ReadinessStatus, IssueTypes, DeviceIssuesCount

If ($null -ne $newRisks) {
    Write-Information -MessageData "$($newRisks.count) Risks found in risk report but not in WindowsUpgradeReadinessRisks"

    Write-Information -MessageData "Updating WindowsUpgradeReadinessRisks with New Risks"
    Write-SqlTableData -ServerInstance $sqlInstance -DatabaseName $sqlDatabase -SchemaName dbo -TableName WindowsUpgradeReadinessRisks -Inputdata $newRisks -Timeout 600  -TrustServerCertificate
}
Else {
    Write-Information -MessageData "No New Risks Found"
}

If ($null -ne $missingRisks) {
    Write-Information -MessageData "$($missingRisks.count) Risks found in WindowsUpgradeReadinessRisks but not in risk report"

    Write-Information -MessageData "Updating deviceIssuesCount to zero for risks found in WindowsUpgradeReadinessRisks but no longer found in risk report."
    $updateRiskToZeroQuery = $missingRisks | Get-ReadinessRiskToZeroQuery    -TableName "WindowsUpgradeReadinessRisks" -DatabaseName $sqlDatabase -InstanceName $sqlInstance
    Foreach ($query in $updateRiskToZeroQuery) {
        Invoke-SQLcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query $query -TrustServerCertificate
    }
}
Else {
    Write-Information -MessageData "No Risks to Update"
}

If ($null -ne $updateRisks) {
    Write-Information -MessageData "$($updateRisks.count) Risks found in both WindowsUpgradeReadinessRisks and risk report"

    Write-Information -MessageData "Updating WindowsUpgradeReadinessRisks with new values for existing risks"

    $updateRiskValuesQuery = $updateRisks  | Get-ReadinessRiskUpdateValueQuery    -TableName "WindowsUpgradeReadinessRisks" -DatabaseName $sqlDatabase -InstanceName $sqlInstance
    Foreach ($query in $updateRiskValuesQuery) {
        Invoke-SQLcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query $query -TrustServerCertificate
    }
}
Else {
    Write-Information -MessageData "No Risks to Update"
}



#
# Issues Report
#


Write-Information -MessageData "Getting Windows Readiness Risk Data Device Report"

$readinessRiskDataDevice = Foreach ($risk in $readinessRiskData) {
    Write-Information -MessageData "Getting Issues for $($risk.AssetName)"
    Get-ReadinessRisksByDevice -total $risk.DeviceIssuesCount -batchSize 50 -assetData $risk -targetOS $targetOS -InformationVariable readinessRiskDataDeviceLog |
        Select-Object -Property * -ExcludeProperty SchemaVersion, RowCountInSnapshot
}

Write-Information  "Exporting Windows Readiness Risk Data Device Report to CSV at $env:tmp\readinessRiskDataDevice--$date.csv"
$readinessRiskDataDevice | Export-CSV -Path "$env:tmp\readinessRiskDataDevice--$date.csv" -NoTypeInformation

Write-Information  "Risk Device Report Log saved: $env:tmp\readinessRiskDataDeviceLog--$date.txt"
$readinessRiskDataDeviceLog | Foreach-Object { $_ | Select-Object -Property * } | Out-String | Out-File -FilePath "$env:tmp\readinessRiskDataDeviceLog--$date.txt"


Write-Information "Truncating the WindowsUpgradeReadinessIssues_LOAD table"
Invoke-Sqlcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query "TRUNCATE TABLE dbo.WindowsUpgradeReadinessIssues_LOAD"  -TrustServerCertificate

Write-Information "Inserting the data from the issues report into the WindowsUpgradeReadinessIssues_LOAD table"
Write-SqlTableData -ServerInstance $sqlInstance -DatabaseName $sqlDatabase  -SchemaName dbo -TableName "WindowsUpgradeReadinessIssues_LOAD" -InputData $readinessRiskDataDevice -Force -Timeout 600  -TrustServerCertificate -Verbose

Write-Information "Select all entries from the issues table where the device id is in the status with a readiness status of 4 and the target OS is $TargetOS"

$missingIssuesQuery = @"
With UniqueUpgradedDevices As (
    SELECT DISTINCT DeviceId,AadDeviceId
    FROM dbo.WindowsUpgradeReadinessStatus WHERE ReadinessStatus = 4 AND TargetOS = '$TargetOS'
) 
SELECT i.* 
FROM dbo.WindowsUpgradeReadinessIssues i
Inner Join UniqueUpgradedDevices 
ON 
    UniqueUpgradedDevices.AadDeviceId = i.AadDeviceId 
    AND 
    UniqueUpgradedDevices.DeviceId = i.DeviceId

"@
$missingIssues      = Invoke-Sqlcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query $missingIssuesQuery -TrustServerCertificate
$missingIssuesCount = $missingIssues | Measure-Object | Select-Object -ExpandProperty Count
Write-Information "Found $missingIssuesCount missing issues"
$missingIssues | ForEach-Object { $_.ReadinessStatus = 255}
If ( $missingIssuesCount -gt 0 ) {
    Try{
        Write-Information "Inserting $missingIssuesCount entries into the issues_load table with a readinessstatus of '255' (upgraded)."
        Write-SqlTableData -ServerInstance $sqlInstance -DatabaseName $sqlDatabase  -SchemaName dbo -TableName WindowsUpgradeReadinessIssues_LOAD -InputData $missingIssues -Force -Timeout 600  -TrustServerCertificate -Verbose
    }
    Catch{
        Write-Error "Failed to insert missing issues into the issues_load table"
        Write-Information $Error[0]
    }
}
Write-Information "Truncating the WindowsUpgradeReadinessIssues table and copying the data from the issues_load table"
$truncateTableCopyLoadSQL = @"
TRUNCATE TABLE WindowsUpgradeReadinessIssues
INSERT INTO WindowsUpgradeReadinessIssues
SELECT * FROM WindowsUpgradeReadinessIssues_LOAD
Where OSVersion NOT LIKE '10.0.22%';
"@
Invoke-Sqlcmd -ServerInstance $sqlInstance -database $sqlDatabase -Query $truncateTableCopyLoadSQL -TrustServerCertificate


$endTime = Get-Date
$elapsed = $endTime - $startTime
Write-Information -MessageData "Elapsed Time: $elapsed"
Stop-Transcript