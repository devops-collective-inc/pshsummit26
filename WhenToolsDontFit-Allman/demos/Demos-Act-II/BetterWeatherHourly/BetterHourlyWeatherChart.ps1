param(
    $Latitude = "47.591",   # Bellevue 47.591
    $Longitude = "-122.149" # Bellevue -122.149
)

# Load necessary .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Initialize Chart object
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Size = '1200,800'

# Create Chart Area
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chart.ChartAreas.Add($chartArea)


Function New-Series {
    param (
        [string]$name,
        [System.Drawing.Color]$color,
        [System.Windows.Forms.DataVisualization.Charting.Chart]$chart
    )
    $series           = New-Object System.Windows.Forms.DataVisualization.Charting.Series -ArgumentList $name
    $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $series.Color     = $color
    
    #$chart.Legends.Add($name)
    #$series.Legend = $name
    $chart.Series.Add($series)
}

Function New-DataPoint {
    param (
        [object]$xValue,
        [object]$yValue,
        [string]$label
    )
    $dataPoint = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint
    $dataPoint.SetValueXY($xValue, $yValue)
    $dataPoint.Label = $label
    Write-Output $dataPoint
}
# Define Data Series and Set Type to Line

# ←↑→↓↖↗↘↙

$windDirection = @{
    N  = "↑"
    NE = "↗"
    E  = "→"
    SE = "↘"
    S  = "↓"
    SW = "↙"
    W  = "←"
    NW = "↖"
}

$weatherDataMetrics = @{
    "CloudCover"       = "Gold"
    "Precipitation"    = "Blue"
    "Temperature"      = "Red"
    "WindSpeed"        = "Purple"
    "WindGustSpeed"    = "Plum"
}

$weatherDataMetrics.GetEnumerator() | ForEach-Object {
    New-Series -name $_.Key -color $_.Value -chart $chart | Out-Null
}

$weather = Invoke-RestMethod -uri "https://weatherapi.pelmorex.com/api/v1/hourly?locale=en-CA&lat=$Latitude&long=$Longitude&unit=metric&count=10"|Select-Object -ExpandProperty hourly
foreach ($entry in $weather | Sort-Object -Property time) {

    $time                 = $(get-date -date $([datetime]$entry.time.utc).ToLocalTime() -Format MM-dd-htt)
    $cloudCoverValue      = $entry.CloudCover
    $popValue             = $entry.POP
    $temperatureValue     = $entry.temperature.value
    $wind                 = $entry.wind
    $windDirectionValue   = $windDirection[$wind.direction]
    $windSpeedValue       = $wind.speed
    $windGustSpeedValue   = $wind.gust

    
    $cloudCoverDataPoint  = New-DataPoint -xValue $time -yValue $cloudCoverValue -label $cloudCoverValue.ToString()
    $popDataPoint         = New-DataPoint -xValue $time -yValue $popValue -label $popValue.ToString()
    $temperatureDataPoint = New-DataPoint -xValue $time -yValue $temperatureValue -label $temperatureValue.ToString()
    $windSpeedDataPoint   = New-DataPoint -xValue $time -yValue $windSpeedValue -label "$windDirectionValue $windSpeedValue km/h"
    $windGustSpeedDataPoint = New-DataPoint -xValue $time -yValue $windGustSpeedValue -label "$windGustSpeedValue km/h"

    
    $chart.Series["CloudCover"].Points.Add($cloudCoverDataPoint) 
    $chart.Series["Precipitation"].Points.Add($popDataPoint)
    $chart.Series["Temperature"].Points.Add($temperatureDataPoint)
    $chart.Series["WindSpeed"].Points.Add($windSpeedDataPoint)
    $chart.Series["WindGustSpeed"].Points.Add($windGustSpeedDataPoint)
}


# Display in a Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Line Graph"
$form.Width = 1200
$form.Height = 800
$form.Controls.Add($chart)
$form.ShowDialog()
