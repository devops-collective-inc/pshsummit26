$Driver = Start-SeFirefox 
Function Get-MLSListing {
    param($ID)
    Enter-SeUrl "https://smartmls.connectmls.com/servlet/QL?D=$($D)&inbox=$($inbox)&ps-focus=$($ID)&ps-report=detail" -Driver $Driver

    $results = Find-SeElement -Driver $Driver -By ClassName -Selection 'modal-body'

    $fav = 'unknown'

    $r = Find-SeElement -Driver $Driver -By ClassName -Selection 'listing-details-header'
    if ($r.FindElementByClassName('heart').GetAttribute('class') -match 'selected') { $fav = 'yes' }
    if ($r.FindElementByClassName('maybe').GetAttribute('class') -match 'selected') { $fav = 'maybe' }
    if ($r.FindElementByClassName('rejected').GetAttribute('class') -match 'selected') { $fav = 'no' }

    $MLS = $r.FindElementByTagName('li').Text.Split('#')[-1].Trim()
    $street = $r.FindElementByClassName('street-price').Text
    $city = $r.FindElementByClassName('city-state-zip').Text
    $Status = (Find-SeElement -Driver $Driver -By ClassName -Selection 'listing_folder_flag' | Select-Object -Last 1 -ExpandProperty Text)
    $price = (Find-SeElement -Driver $Driver -By ClassName -Selection 'street-price' | Where-Object { $_.Text -match '\$' }).Text

    $iconText = Find-SeElement -Driver $Driver -By ClassName -Selection 'col-lg-5' | Select-Object -First 1 -ExpandProperty Text
    $t = $iconText.Split("`n")
    $year = $t | Where-Object { $_ -match 'built' } | ForEach-Object { $_.tolower().Replace('built', '').Trim() }
    $sqft = $t | Where-Object { $_ -match 'sqft' } | ForEach-Object { $_.tolower().Replace('sqft', '').Replace(',', '').Trim() }
    $beds = $t | Where-Object { $_ -match 'beds' } | ForEach-Object { $_.tolower().Replace('beds', '').Trim() }
    $baths = $t | Where-Object { $_ -match 'baths' } | ForEach-Object { $_.tolower().Replace('baths', '').Replace(',', '').Trim() }
    $properties = [ordered]@{
        NickName = ''
        id       = $id
        street   = $street
        city     = $city.Split(',')[0].Trim()
        MLS      = $MLS
        Price    = $price
        Status   = $Status
        Final    = ''
        Viewed   = 'TBD'
        Notes    = ''
        beds     = $beds
        baths    = $baths
        sqft     = $sqft
        year     = $year
        fav      = $fav
    }
    $l = [pscustomobject]$properties

    $rowHeaders = @(
        '^Basement Description'
        'Listing Date'
        'Heat Type'
        'Water Source'
        'Sewage System'
        'Cooling System'
        'Possession Availability'
        'Swimming Pool'
        '^High School'
        'HOA Fee Amount'
        'HOA Fee Frequency'
    )
    $rows = Find-SeElement -Driver $Driver -By ClassName -Selection 'listing-details-row' | Select-Object -ExpandProperty Text

    $rowHeaders | ForEach-Object {
        AddMember $l $_.Replace('^', '').Replace(' ', '') (Get-RowValue $_) 
    }

    $l
}