# 1) Load the previously saved tracking spreadsheet.
#    Import-Excel (from the ImportExcel module) reads the sheet into an array of objects.
#    ErrorAction Stop ensures we halt immediately if the file is missing or unreadable.
$myList = Import-Excel -Path $pre_excelPath -WorksheetName $worksheetName -ErrorAction Stop

# 2) Pull the current live listings from the MLS source.
#    Get-MLSListing is a custom function defined in Get-MLSListing.ps1.
$listings = Get-MLSListing

# 3) Find which live MLS listings already exist in our tracking spreadsheet.
#    '-in' checks whether each listing id is present in the saved list.
$matchedListings = $listings | Where-Object { $_.id -in $myList.Id }


# 4) Detect and report any status changes on listings we are already tracking.
foreach ($ml in $matchedListings) {
    # Match the live listing back to our saved row by id.
    $m = $myList | Where-Object { $_.Id -eq $ml.Id }

    # If the live status differs from what we saved, log the change and update in memory.
    if ($m.Status -ne $ml.Status) {
        # Show old -> new status and the street address for easy identification.
        "$($m.Status) --> $($ml.Status) : $($m.Street)"
        # Update the in-memory object so the change is written back to Excel later.
        $m.Status = $ml.Status
    }
}

# 5) Shape brand-new MLS listings (ones not yet in our spreadsheet) into tracking objects.
#    '-notin' is the inverse of '-in': it keeps only listings absent from our saved list.
$listingsToAdd = foreach ($l in $listings | Where-Object { $_.id -notin $myList.Id } ) {
    # Create a custom object with every column our spreadsheet expects.
    # New listings start with blank NickName/Notes/Final and 'TBD' for Viewed.
    [pscustomobject]@{
        NickName = ''
        id       = $l.id
        street   = $l.street
        city     = $l.city
        MLS      = $l.MLS
        Price    = $l.Price
        Status   = $l.Status
        Final    = ''
        Viewed   = 'TBD'
        Notes    = ''
        beds     = $l.beds
        baths    = $l.baths
        sqft     = $l.sqft
        year     = $l.year
        fav      = $l.fav
    }
}


# 6) Merge existing tracked listings with the newly discovered ones.
#    Wrapping each in @() guarantees we always get an array even if one side is empty.
$allListings = @($myList) + @($listingsToAdd)

# 7) Define sort priorities for the 'Final' decision column.
#    Lower numbers appear first: active deals (submitted/offer) surface before rejections.
$finalOrder = @{ '' = 0; 'submitted' = 1; 'offer' = 2; 'rejected' = 3; 'maybe' = 4 }

# Scriptblock used as a computed sort key for the 'Viewed' column.
# TBD = not yet visited (priority 0 = top), visited = 1, maybe = 2, no = 20 (bottom).
$viewedPriority = { $vl = ($_.Viewed ?? '').ToLower(); if ($vl -eq 'tbd') { 0 } elseif ($vl -eq 'maybe') { 2 } elseif ($vl -eq 'no') { 20 } else { 1 } }

# 8) Sort all listings into a meaningful display order.
#    - First bucket: listings with a known Final status, sorted by deal stage then viewed state.
#    - Second bucket: listings without a Final status, sorted by viewed priority then date.
$sortedListings = @(
    $allListings | Where-Object { $finalOrder.ContainsKey(($_.Final ?? '').ToLower()) } |
        Sort-Object { $finalOrder[($_.Final ?? '').ToLower()] }, $viewedPriority, 'Viewed'
    $allListings | Where-Object { -not $finalOrder.ContainsKey(($_.Final ?? '').ToLower()) } |
        Sort-Object @{Expression=$viewedPriority; Descending=$false}, @{Expression='Viewed'; Descending=$false}, @{Expression='Final'; Descending=$true}
)


# 9) Write the sorted listings to Excel.
#    -ClearSheet replaces any existing data so stale rows don't linger.
#    -PassThru returns the open package object so we can apply further formatting.
#    -TableName / -TableStyle give it a styled Excel table with filter dropdowns.
$pkg = $sortedListings | Export-Excel -Path $excelPath -ClearSheet -WorksheetName $worksheetName -PassThru -AutoSize -TableName Sales -TableStyle Medium1

# Get a direct reference to the worksheet for fine-grained formatting calls.
$sheet = $pkg.Workbook.Worksheets[$worksheetName]

# 10) Apply conditional formatting rules so statuses are colour-coded at a glance.
#     Each rule tests a column H (Final) or I (Viewed) formula and paints the full row.
#     FromArgb values are ARGB integers representing specific colours.
Add-ConditionalFormatting -Worksheet $sheet -Range "A2:Z$($allListings.Count+1)" -ConditionValue '=$H2="no"'        -RuleType Expression -FontColor 'Red'                                          # 'no' = not interested, red text
Add-ConditionalFormatting -Worksheet $sheet -Range "A2:Z$($allListings.Count+1)" -ConditionValue '=$I2="TBD"'      -RuleType Expression -BackgroundColor ([System.Drawing.Color]::FromArgb(12642037))  # not yet viewed, light blue
Add-ConditionalFormatting -Worksheet $sheet -Range "A2:Z$($allListings.Count+1)" -ConditionValue '=$H2="rejected"' -RuleType Expression -BackgroundColor ([System.Drawing.Color]::FromArgb(15837571))  # rejected offer, light red
Add-ConditionalFormatting -Worksheet $sheet -Range "A2:Z$($allListings.Count+1)" -ConditionValue '=$H2="submitted"' -RuleType Expression -BackgroundColor ([System.Drawing.Color]::FromArgb(12710088)) # offer submitted, green
Add-ConditionalFormatting -Worksheet $sheet -Range "A2:Z$($allListings.Count+1)" -ConditionValue '=$H2="offer"'    -RuleType Expression -BackgroundColor ([System.Drawing.Color]::FromArgb(14982877))  # active offer, yellow

# 11) Polish column formatting: currency, dates, and explicit widths.
Set-ExcelRange -Worksheet $sheet -Range "F:F" -NumberFormat "\$#,##0;(\$#,##0)" -AutoSize  # Price column as currency
Set-ExcelRange -Worksheet $sheet -Range "Q:Q" -NumberFormat "m/d/yyyy" -AutoSize           # Date column
Set-ExcelRange -Worksheet $sheet -Range "G:G" -Width 17                                    # Status column readable width
Set-ExcelRange -Worksheet $sheet -Range "B:B" -Width 0                                     # Hide internal id column
Set-ExcelRange -Worksheet $sheet -Range "E:E" -Width 0                                     # Hide MLS column
Set-ExcelRange -Worksheet $sheet -Range "F:F" -Width 0                                     # Hide Price column (shown elsewhere)
Set-ExcelRange -Worksheet $sheet -Range "J:J" -Width 75                                    # Notes column needs extra width

# 12) Save and close the Excel package, then open the file so you can review it immediately.
Close-ExcelPackage -ExcelPackage $pkg -Show

