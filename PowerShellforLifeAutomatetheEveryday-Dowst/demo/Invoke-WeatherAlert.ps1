# Find local station at - https://cdn.weatherstem.com/dashboard/data/dynamic




$weather = Invoke-RestMethod -Uri 'https://cdn.weatherstem.com/dashboard/data/dynamic/model/denton/twu/latest.json'
$weather.records | Format-Table

$WetBulb = $weather.records | Where-Object { $_.sensor_name -eq 'Wet Bulb Globe Temperature' }


# 3) Classify the WBGT reading into a color-coded heat-stress condition.
#    Each scriptblock { $_ ... } is a conditional test evaluated against the value.
#    Note: ranges overlap intentionally – PowerShell tests every case and the last
#    matching one wins, so the most severe applicable rule takes effect.
switch ($WetBulb.value) {
    { $_ -le 82.1 } { 
        $condition = "Green"
        $Body = "Normal Activities, provide three separate 3 minute breaks each hour of training, or a 10 minute break every 40 minutes" 
    }
    { $_ -gt 82.1 } { 
        $condition = "Yellow"
        $Body = "Use discretion, provide three separate 4 minute breaks each hour, or a 12 minute break every 40 minutes of continuous training" 
    }
    { $_ -gt 87 } { 
        $condition = "Orange"
        $Body = "Maximum two hours of training time with four separate 4 minute breaks each hour, or a 10 minute break after 30 minutes of continuous training" 
    }
    { $_ -gt 90 } { 
        $condition = "Red"
        $Body = "Maximum of one hour of training with four separate 4 minute breaks within the hour. No additional conditioning allowed." 
    }
    { $_ -ge 92 } { 
        $condition = "Black"
        $Body = "No outdoor training, delay training until cooler or cancel." 
    }
}

# Print the condition name and guidance message to the console.
Write-Host "Condition: $condition`n$Body"


# 4) Locate the target GroupMe group by name so we can post into it.
#    $GroupMePAT should be a pre-existing variable holding your GroupMe access token.
$GroupName = 'Soccer Test'

# Retrieve all groups the account belongs to from the GroupMe API.
$groupMemberships = Invoke-RestMethod -Uri "https://api.groupme.com/v3/groups?token=$GroupMePAT"

# Filter to the single group whose name matches $GroupName.
$group = $groupMemberships.response | Where-Object { $_.name -eq $GroupName }

# Display the group object so you can inspect its id and other properties.
$group


# 5) Build the notification message text from the condition variables set above.
$Message = "Condition: $condition`n$Body"

# 6) Wrap the message in the JSON structure the GroupMe API expects.
#    source_guid is a unique ID for this message to prevent accidental duplicates.
#    ConvertTo-Json serialises the PowerShell hashtable into a JSON string.
$Body = @{
    message = @{
        "source_guid" = (New-Guid).ToString()
        "text"        = $Message
    }
} | ConvertTo-Json

# 7) Send the message to the GroupMe group via the REST API.
#    Splatting (@WebRequestParam) keeps the Invoke-WebRequest call readable.
$WebRequestParam = @{
    Uri         = "https://api.groupme.com/v3/groups/$($group.id)/messages?token=$GroupMePAT"
    Body        = $Body
    Method      = 'Post'
    ContentType = 'application/json'
}
Invoke-WebRequest @WebRequestParam


# 8) Fetch historical WBGT readings from the station's raw text feed.
#    The feed is headerless CSV, so we supply our own column names.
$previousRaw = Invoke-RestMethod -Uri 'https://cdn.weatherstem.com/twc/data/dynamic/denton.twu.txt'

# Define column names that map to each comma-separated field in the raw data.
# 'wbt' is the Wet Bulb Temperature column we care about most.
$header = 'timestamp,a,b,c,d,e,f,g,h,wbt'

# Parse the raw text into structured PowerShell objects using the custom header.
$previous = $previousRaw | ConvertFrom-Csv -Header $header.Split(',') 

# 9) Group readings into 15-minute time buckets to identify trends over time.
#    Group-TimeSpan is a custom/module function that buckets by the timestamp property.
$grouped = $previous | Group-TimeSpan -Minutes 15 -Property timestamp

# Calculate the average and maximum WBGT value within each 15-minute window.
$grouped | Measure-TimeSpan -Property wbt -Average -Maximum


# 10) Quick sanity check: compute the average WBGT for the most recent 30 readings.
#     Sorting by timestamp first ensures we truly get the latest entries.
$previous | Sort-Object timestamp | Select-Object -Last 30 | Measure-Object -Property wbt -Average
