# Shaping Data with PowerShell

A non-comprehensive guide to transforming raw data into meaningful operational views, reports, and dashboards using PowerShell cmdlets.

---

## 1. Quick Console Summary

### Display Raw Server Data

This displays the raw server data object stored in the `$serverData` variable. This is the starting point for all transformations shown in this script.

```powershell
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
```

---

### Sorted and Filtered Table View

This demonstrates that shaping data isn't always about exporting, sometimes it's about giving operational teams a better view of the data in the console.

- **`Sort-Object Environment, ServerName`** - Orders the data first by Environment, then by ServerName. This provides a logical, grouped view in the output.
- **`Select-Object ServerName, Environment, Role, ComplianceStatus, DaysSincePatched`** - Selects only the relevant columns to display, filtering out unnecessary properties and making the output more readable.
- **`Format-Table -AutoSize`** - Formats the output as a table with column widths automatically adjusted to fit the content.

```powershell
$serverData |
    Sort-Object Environment, ServerName |
    Select-Object ServerName, Environment, Role, ComplianceStatus, DaysSincePatched |
    Format-Table -AutoSize
```

---

### Environment Summary by Count

Quickly see how many servers exist in each environment (e.g., Production, Staging, Development).

- **`Group-Object Environment`** - Groups servers by their Environment property, creating aggregated groups.
- **`Select-Object Name, Count`** - Displays the environment name and the number of servers in each environment.

```powershell
$serverData |
    Group-Object Environment |
    Select-Object Name, Count
```

---

### Rich Grouped Environment Summary

Provides operations teams with a comprehensive health summary per environment, highlighting problem areas.

- **`Group-Object Environment`** - Organizes servers by environment.
- **`ForEach-Object { ... }`** - Iterates through each group to create a custom summary object.
- **`[pscustomobject]@{ ... }`** - Creates a custom object with calculated properties for better reporting.
- **`($_.Group | Where-Object ComplianceStatus -eq 'NonCompliant').Count`** - Counts non-compliant servers within each group.
- **`($_.Group | Where-Object MonitoringEnabled -eq $false).Count`** - Counts servers with disabled monitoring in each group.
- **`Format-Table -AutoSize`** - Displays the results in a formatted table.

```powershell
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
```

---

## 2. Shape for an Inventory Summary

### Create Inventory with Calculated Properties

Transforms raw data into inventory-specific columns that are meaningful to infrastructure teams, including calculated values.

- **`Select-Object`** - Selects specific properties and allows calculated (derived) properties.
- **`@{Name='PatchAgeDays';Expression={$_.DaysSincePatched}}`** - Renames `DaysSincePatched` to `PatchAgeDays` for clearer reporting.
- **`@{Name='FreeDiskPercentEstimate';Expression={...}}`** - Creates a new calculated property that converts free disk GB into a percentage (assuming 250 GB total capacity).
- **`[math]::Round(..., 2)`** - Rounds the percentage to 2 decimal places for readability.

```powershell
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
```

---

### Display and Export Inventory

Inventory data is about selecting properties that matter to your audience, not dumping every property. This creates a focused, shareable inventory report.

- **`Format-Table -AutoSize`** - Displays the inventory in a formatted table view in the console.
- **`Export-Csv '.\server-inventory.csv' -NoTypeInformation`** - Exports the inventory to a CSV file without PowerShell type information headers.
- **`code '.\server-inventory.csv'`** - Opens the CSV file in VS Code for review.

```powershell
$inventorySummary | Format-Table -AutoSize

$inventorySummary | Export-Csv '.\server-inventory.csv' -NoTypeInformation

code '.\server-inventory.csv'
```

---

## 3. Shape for an Audit or Compliance Report

### Filter for Problem Systems

Transforms raw compliance data into explainable audit findings that non-technical stakeholders can understand.

- **`Where-Object { ... }`** - Filters to only servers with at least one problem:
  - Compliance status is non-compliant, OR
  - Patches are older than 30 days, OR
  - Monitoring is disabled
- **`Select-Object`** - Includes relevant audit properties and a custom `Finding` property.
- **`$findings = @()`** - Creates an empty array to collect findings for each server.
- **`if ($_.ComplianceStatus -eq 'NonCompliant')`** - Checks if the server is non-compliant and adds a finding if true.
- **`if ($_.DaysSincePatched -gt 30)`** - Checks if patches are overdue and adds a finding if true.
- **`if ($_.MonitoringEnabled -eq $false)`** - Checks if monitoring is disabled and adds a finding if true.
- **`$findings -join '; '`** - Combines all findings into a single semicolon-separated string for display.

```powershell
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
```

---

### Display and Export Audit Report

Audit reporting turns raw facts into actionable findings that demonstrate compliance posture.

- **`Format-Table -Wrap -AutoSize`** - Displays results with text wrapping enabled for wide fields and auto-sized columns.
- **`Export-Csv`** - Exports to CSV for sharing with compliance teams.
- **`code`** - Opens the file for review.

```powershell
$auditFindings | Format-Table -Wrap -AutoSize

$auditFindings | Export-Csv '.\server-audit.csv' -NoTypeInformation

code '.\server-audit.csv'
```

---

## 4. Shape for Dashboard or API Output

### Create Dashboard Summary Object

Creates a structured, stable schema suitable for APIs and dashboards rather than raw object dumps.

- **`Get-Date`** - Captures the current date and time for the dashboard timestamp.
- **`.Count`** - Gets the total number of servers in the dataset.
- **`Where-Object ComplianceStatus -eq 'Compliant'`** - Filters to compliant servers and counts them.
- **`Where-Object ComplianceStatus -eq 'NonCompliant'`** - Filters to non-compliant servers and counts them.
- **`Where-Object MonitoringEnabled -eq $false`** - Counts servers with disabled monitoring.
- **`Group-Object Environment`** - Groups servers by environment for per-environment metrics.
- **`Sort-Object DaysSincePatched -Descending | Select-Object -First 3`** - Identifies the 3 servers with the oldest patches.

```powershell
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
```

---

### Convert to JSON and Export

Dashboards and APIs expect a stable, intentional schema, not raw PowerShell objects. JSON is a standard interchange format.

- **`ConvertTo-Json -Depth 5`** - Converts the object to JSON with up to 5 levels of nesting, suitable for APIs and dashboards.
- **`Set-Content '.\server-data.json'`** - Saves the JSON to a file.

```powershell
$dashboardData | ConvertTo-Json -Depth 5

$dashboardData | ConvertTo-Json -Depth 5 | Set-Content '.\server-data.json'
```

---

## 5. Shaping Techniques Reference

### Calculated Properties with Select-Object

Adds a boolean property `PatchedRecently` that is true if patches are 30 days old or less. Useful for status classifications.

```powershell
$serverData | Select-Object ServerName,
    Environment,
    @{Name='PatchedRecently';Expression={$_.DaysSincePatched -le 30}}
```

---

### Group-Object for Rollups

Groups servers by compliance status, enabling summary calculations and trend analysis per group.

```powershell
$serverData | Group-Object ComplianceStatus
```

---

### Sort-Object for Ranking

Orders servers by patch age in descending order (oldest patches first). Useful for identifying servers needing immediate attention.

```powershell
$serverData | Sort-Object DaysSincePatched -Descending
```

---

### Measure-Object for Statistics

Calculates:
- **`-Sum`** - Total memory across all servers
- **`-Average`** - Average memory per server
- **`-Maximum`** - Highest memory allocation
- **`-Minimum`** - Lowest memory allocation

Useful for capacity planning reports.

```powershell
$serverData | Measure-Object MemoryGB -Sum -Average -Maximum -Minimum
```

---

### Where-Object for Filtered Reports

Filters the dataset to only Production servers. Can be combined with other cmdlets for environment-specific reports.

```powershell
$serverData | Where-Object Environment -eq 'Production'
```

---

### ForEach-Object for Custom Shapes

Iterates through each server and creates a simplified custom object with human-readable status labels. Useful for simplified views.

```powershell
$serverData | ForEach-Object {
    [pscustomobject]@{
        Server      = $_.ServerName
        PatchStatus = if ($_.DaysSincePatched -le 30) { 'Current' } else { 'Stale' }
    }
}
```

---

## 6. HTML Reporting

### Generate and View HTML Report

Creates a quick HTML report without needing a full dashboard stack. Useful for one-off compliance reports, executive summaries, or sharing findings with non-technical stakeholders.

- **`ConvertTo-Html -Title 'Server Compliance Report'`** - Converts the data into an HTML table with the specified title. Includes default styling.
- **`Set-Content '.\server-report.html'`** - Saves the HTML to a file.

```powershell
$serverData |
    Select-Object ServerName, Environment, ComplianceStatus, DaysSincePatched |
    ConvertTo-Html -Title 'Server Compliance Report' |
    Set-Content '.\server-report.html'
```

---

## Summary

Data shaping in PowerShell is about transforming raw data to meet specific needs: