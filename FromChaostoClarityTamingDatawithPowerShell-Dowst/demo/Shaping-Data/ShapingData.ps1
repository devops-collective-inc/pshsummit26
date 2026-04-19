# Generate some sample server inventory data
$serverData = @(
    [pscustomobject]@{
        ServerName        = 'SQL-PROD-01'
        Environment       = 'Production'
        Role              = 'SQL'
        Owner             = 'Finance'
        OperatingSystem   = 'Windows Server 2022'
        IsVirtual         = $true
        LastPatched       = [datetime]'2026-03-15'
        DaysSincePatched  = 27
        ComplianceStatus  = 'Compliant'
        MonitoringEnabled = $true
        CpuCount          = 8
        MemoryGB          = 64
        DiskFreeGB        = 187.42
    }
    [pscustomobject]@{
        ServerName        = 'WEB-PROD-01'
        Environment       = 'Production'
        Role              = 'Web'
        Owner             = 'Marketing'
        OperatingSystem   = 'Windows Server 2022'
        IsVirtual         = $true
        LastPatched       = [datetime]'2026-02-10'
        DaysSincePatched  = 60
        ComplianceStatus  = 'NonCompliant'
        MonitoringEnabled = $true
        CpuCount          = 4
        MemoryGB          = 16
        DiskFreeGB        = 42.18
    }
    [pscustomobject]@{
        ServerName        = 'APP-QA-01'
        Environment       = 'QA'
        Role              = 'Application'
        Owner             = 'Engineering'
        OperatingSystem   = 'Windows Server 2019'
        IsVirtual         = $true
        LastPatched       = [datetime]'2026-03-22'
        DaysSincePatched  = 20
        ComplianceStatus  = 'Compliant'
        MonitoringEnabled = $false
        CpuCount          = 4
        MemoryGB          = 32
        DiskFreeGB        = 88.70
    }
    [pscustomobject]@{
        ServerName        = 'FILE-DEV-01'
        Environment       = 'Development'
        Role              = 'File'
        Owner             = 'IT'
        OperatingSystem   = 'Windows Server 2019'
        IsVirtual         = $false
        LastPatched       = [datetime]'2026-01-28'
        DaysSincePatched  = 73
        ComplianceStatus  = 'NonCompliant'
        MonitoringEnabled = $false
        CpuCount          = 8
        MemoryGB          = 32
        DiskFreeGB        = 210.05
    }
)

# Start simple. Shaping is not always exporting. Sometimes it is just giving a better operational view.

$serverData |
    Sort-Object Environment, ServerName |
    Select-Object ServerName, Environment, Role, ComplianceStatus, DaysSincePatched |
    Format-Table -AutoSize


# Then summarize by environment:

$serverData |
    Group-Object Environment |
    Select-Object Name, Count

# Or create a richer grouped summary:

$serverData |
    Group-Object Environment |
    ForEach-Object {
        [pscustomobject]@{
            Environment        = $_.Name
            ServerCount        = $_.Count
            NonCompliant       = ($_.Group | Where-Object ComplianceStatus -eq 'NonCompliant').Count
            MonitoringDisabled = ($_.Group | Where-Object MonitoringEnabled -eq $false).Count
        }
    } |
    Format-Table -AutoSize


# 2. Shape for an inventory summary

# Select, rename, and calculate properties.

$inventorySummary = $serverData |
    Select-Object ServerName,
        Environment,
        Role,
        Owner,
        OperatingSystem,
        @{Name='PatchAgeDays';Expression={$_.DaysSincePatched}},
        @{Name='FreeDiskPercentEstimate';Expression={
            [math]::Round(($_.DiskFreeGB / 250) * 100, 2)
        }}

$inventorySummary | Format-Table -AutoSize

# Export it:

$inventorySummary | Export-Csv '.\server-inventory.csv' -NoTypeInformation

# Inventory data is rarely about dumping every property. 
# It is about selecting the data that matter to the audience.

# 3. Shape for an audit or compliance report

# Filter to only problem systems:

$auditFindings = $serverData |
    Where-Object {
        $_.ComplianceStatus -eq 'NonCompliant' -or
        $_.DaysSincePatched -gt 30 -or
        $_.MonitoringEnabled -eq $false
    } |
    Select-Object ServerName,
        Environment,
        Owner,
        ComplianceStatus,
        MonitoringEnabled,
        LastPatched,
        DaysSincePatched,
        @{Name='Finding';Expression={
            $findings = @()

            if ($_.ComplianceStatus -eq 'NonCompliant') {
                $findings += 'Compliance failure'
            }

            if ($_.DaysSincePatched -gt 30) {
                $findings += 'Patch window exceeded'
            }

            if ($_.MonitoringEnabled -eq $false) {
                $findings += 'Monitoring disabled'
            }

            $findings -join '; '
        }}

$auditFindings | Format-Table -Wrap -AutoSize

# Export it:

$auditFindings | Export-Csv '.\server-audit.csv' -NoTypeInformation

# Audit reporting is about turning raw facts into explainable findings.

# 4. Shape for dashboard or API output

# Create a dashboard summary object:

$dashboardData = [pscustomobject]@{
    GeneratedAt        = Get-Date
    TotalServers       = $serverData.Count
    CompliantServers   = ($serverData | Where-Object ComplianceStatus -eq 'Compliant').Count
    NonCompliant       = ($serverData | Where-Object ComplianceStatus -eq 'NonCompliant').Count
    MonitoringDisabled = ($serverData | Where-Object MonitoringEnabled -eq $false).Count
    Environments       = $serverData |
        Group-Object Environment |
        ForEach-Object {
            [pscustomobject]@{
                Name              = $_.Name
                ServerCount       = $_.Count
                NonCompliantCount = ($_.Group | Where-Object ComplianceStatus -eq 'NonCompliant').Count
            }
        }
    TopPatchAges = $serverData |
        Sort-Object DaysSincePatched -Descending |
        Select-Object -First 3 ServerName, Environment, DaysSincePatched
}

$dashboardData | ConvertTo-Json -Depth 5


# Export it

$dashboardData | ConvertTo-Json -Depth 5 | Set-Content '.\server-data.json'

# Dashboards and APIs usually do not want your raw objects. They want a stable, intentional schema.


# 5. Shaping techniques

## Select-Object with calculated properties

$serverData | Select-Object ServerName,
    Environment,
    @{Name='PatchedRecently';Expression={$_.DaysSincePatched -le 30}}


## Group-Object for rollups

$serverData | Group-Object ComplianceStatus

## Sort-Object for ranking

$serverData | Sort-Object DaysSincePatched -Descending


## Measure-Object for totals and averages

$serverData | Measure-Object MemoryGB -Sum -Average -Maximum -Minimum


## Where-Object for filtered reports

$serverData | Where-Object Environment -eq 'Production'

## ForEach-Object for custom shapes

$serverData | ForEach-Object {
    [pscustomobject]@{
        Server      = $_.ServerName
        PatchStatus = if ($_.DaysSincePatched -le 30) { 'Current' } else { 'Stale' }
    }
}

# 6. Bonus HTML reporting

# You can even do a quick HTML report without needing a full dashboard stack:

$serverData |
    Select-Object ServerName, Environment, ComplianceStatus, DaysSincePatched |
    ConvertTo-Html -Title 'Server Compliance Report' |
    Set-Content '.\server-report.html'