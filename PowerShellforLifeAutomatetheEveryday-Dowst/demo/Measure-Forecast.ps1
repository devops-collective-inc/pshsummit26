# ── Input validation ─────────────────────────────────────────────────────────
# A rate-of-change calculation needs at least two points (a start and an end).
# Throwing here stops execution immediately with a clear message.
if ($data.Count -lt 2) {
    throw "Need at least two data points to calculate a rate."
}

# Sort ascending by DateTime so all calculations assume chronological order.
# Without this, any out-of-order rows would produce incorrect rates.
$data = $data | Sort-Object DateTime

$first = $data[0]      # earliest measurement (index 0 after sort)
$last  = $data[-1]     # most recent measurement (index -1 = last element)

# ── Method 1: Overall (end-to-end) rate of change ────────────────────────────
# The simplest forecasting method: draw one straight line from the very first
# data point to the very last and use that slope to project forward.
# Pro: stable and noise-resistant.  Con: ignores recent acceleration/deceleration.

# Total elapsed time between first and last reading, in minutes.
$totalMinutes = ($last.DateTime - $first.DateTime).TotalMinutes

# Net change in the measured value over the entire dataset.
$totalChange  = $last.Average - $first.Average

# Slope = rise / run  →  how many units change per minute on average.
$overallRatePerMinute = $totalChange / $totalMinutes

# Scale to per-hour so the projection arithmetic below is intuitive.
$overallRatePerHour   = $overallRatePerMinute * 60

# Forecast: start from the last known value and add one hour's worth of change.
$overallProjection1Hr = $last.Average + $overallRatePerHour

# ── Method 2: Per-interval rates ─────────────────────────────────────────────
# Instead of one overall slope, compute the rate between every adjacent pair
# of data points.  This reveals how fast the value is changing right now versus
# earlier, capturing short-term spikes or slowdowns the overall rate would miss.
$intervals = for ($i = 1; $i -lt $data.Count; $i++) {

    # 'prev' and 'curr' are the two consecutive readings forming this interval.
    $prev = $data[$i - 1]
    $curr = $data[$i]

    # Time gap between these two readings.
    $minutes = ($curr.DateTime - $prev.DateTime).TotalMinutes

    # Value difference between these two readings.
    $change  = $curr.Average - $prev.Average

    # Per-minute rate for this specific interval.
    $ratePerMinute = $change / $minutes

    # Scale to per-hour for consistent comparison with the other methods.
    $ratePerHour   = $ratePerMinute * 60

    # Emit one summary object per interval; the for-loop collects them all.
    [pscustomobject]@{
        Start         = $prev.DateTime
        End           = $curr.atTime
        Change        = [math]::Round($change, 4)
        Minutes       = $minutes
        RatePerHour   = [math]::Round($ratePerHour, 4)
    }
}

# Mean of all per-interval rates → a smoothed trend that is less skewed by
# a single noisy reading than the overall end-to-end slope.
$avgIntervalRatePerHour = ($intervals | Measure-Object RatePerHour -Average).Average

# The rate from the most recent interval only → useful for detecting whether
# the value is currently accelerating faster than the historical average.
$lastIntervalRatePerHour = $intervals[-1].RatePerHour

# Apply each rate forward from the last known reading to get 1-hour forecasts.
$avgIntervalProjection1Hr  = $last.Average + $avgIntervalRatePerHour
$lastIntervalProjection1Hr = $last.Average + $lastIntervalRatePerHour

# ── Method 3: Ordinary Least-Squares (OLS) linear regression ─────────────────
# Fits the best straight line through ALL data points simultaneously, minimising
# the total squared error.  More statistically robust than the other two methods
# because every reading influences the result, not just the endpoints or the
# most recent gap.
#
# Formula:  y = m·x + b
#   y = predicted value (Average)
#   x = time in minutes since the first reading
#   m = slope  (rate of change per minute)
#   b = y-intercept  (predicted value at x = 0, i.e., the first reading)

# Convert DateTime values to numeric X-coordinates (minutes since first point).
# Regression formulas only work with numbers, not DateTime objects.
$points = foreach ($row in $data) {
    [pscustomobject]@{
        X = ($row.DateTime - $first.DateTime).TotalMinutes
        Y = [double]$row.Average
    }
}

# Pre-compute the five sums that the OLS closed-form formula requires.
$n    = $points.Count
$sumX  = ($points | Measure-Object X -Sum).Sum          # Σx
$sumY  = ($points | Measure-Object Y -Sum).Sum          # Σy
$sumXY = ($points | ForEach-Object { $_.X * $_.Y } | Measure-Object -Sum).Sum  # Σ(x·y)
$sumX2 = ($points | ForEach-Object { $_.X * $_.X } | Measure-Object -Sum).Sum  # Σ(x²)

# OLS slope formula:  m = (n·Σxy − Σx·Σy) / (n·Σx² − (Σx)²)
$slopePerMinute = (($n * $sumXY) - ($sumX * $sumY)) /
                  (($n * $sumX2) - ($sumX * $sumX))

# OLS intercept formula:  b = (Σy − m·Σx) / n
$intercept = ($sumY - ($slopePerMinute * $sumX)) / $n

# Scale slope to per-hour so it is comparable with the other methods.
$slopePerHour = $slopePerMinute * 60

# To forecast, convert the target time to an X-value and evaluate y = m·x + b.
$forecastTime = $last.DateTime.AddHours(1)                               # when we want to predict
$forecastX    = ($forecastTime - $first.DateTime).TotalMinutes           # numeric X for that time
$regressionProjection1Hr = ($slopePerMinute * $forecastX) + $intercept  # predicted value

# ── Output ────────────────────────────────────────────────────────────────────

# Section 1: show the single overall rate and its 1-hour projection.
Write-Host "`n=== OVERALL RATE ===" -ForegroundColor Cyan
[pscustomobject]@{
    RatePerHour       = [math]::Round($overallRatePerHour, 4)
    ProjectionIn1Hour = [math]::Round($overallProjection1Hr, 4)
} | Format-List

# Section 2: show every per-interval rate in a table so you can spot trends
# or anomalies (e.g., one interval that was much faster than the rest).
Write-Host "`n=== INTERVAL RATES ===" -ForegroundColor Cyan
$intervals | Format-Table -AutoSize

# Section 3: side-by-side comparison of all three methods.
# Comparing them tells you how stable the trend is:
#   - If all four projections are close → consistent, predictable trend.
#   - If Projection_LastInterval is much higher → recent acceleration.
#   - Projection_Regression is usually the most statistically reliable.
Write-Host "`n=== SUMMARY COMPARISON ===" -ForegroundColor Cyan
[pscustomobject]@{
    AvgIntervalRatePerHour      = [math]::Round($avgIntervalRatePerHour, 4)
    LastIntervalRatePerHour     = [math]::Round($lastIntervalRatePerHour, 4)
    RegressionRatePerHour       = [math]::Round($slopePerHour, 4)
    Projection_Overall          = [math]::Round($overallProjection1Hr, 4)
    Projection_AvgIntervals     = [math]::Round($avgIntervalProjection1Hr, 4)
    Projection_LastInterval     = [math]::Round($lastIntervalProjection1Hr, 4)
    Projection_Regression       = [math]::Round($regressionProjection1Hr, 4)
}

$previous | Sort-Object timestamp | Select-Object -Last 30 | Measure-Object -Property wbt -Average
$previous | Sort-Object timestamp | Select-Object -Last 30 | Measure-Object -Property wbt -Average
$previous | Sort-Object timestamp | Select-Object -Last 30 | Measure-Object -Property wbt -Average
