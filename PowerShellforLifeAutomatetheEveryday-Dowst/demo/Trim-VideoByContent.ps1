# Select the source video file to process.
$v = Get-Item -Path '.\Video\yourvideo.mp4'

# Build an ffmpeg command that exports one frame every 5 seconds
# and resizes each frame to 1280x720.
$cmd = "ffmpeg -i ""$($v.FullName)"" -vf fps=1/5 -s 1280x720 ""$($v.DirectoryName)\$($v.BaseName)_%04d.jpg"""

# Run the command string above.
Invoke-Expression $cmd



# Load extracted JPG frames from the same folder as the video.
$CompareCaptures = Get-ChildItem -Path $v.DirectoryName -Filter '*.jpg'
# Sample pixels from the first frame as a quick inspection step.
$pixels = Get-ImagePixels -ReferenceFile $CompareCaptures[0] -Increment 10
# Show color distribution by pixel name/count to understand frame makeup.
$pixels.Pixels | Group-Object Name | Sort-Object Count



# Re-read frames for cleaning pass.
$CompareCaptures = Get-ChildItem -Path $v.DirectoryName -Filter '*.jpg'
# Keep only captures that do not match the heavy grey overlay condition.
$CleanCaptures = foreach ($c in $CompareCaptures) {

    # Progress bar while processing each frame image.
    Write-Progress -Activity "Extracting pixels" -Status "$($c.Name)" -PercentComplete (($CompareCaptures.IndexOf($c) / $CompareCaptures.Count) * 100) -Id 1

    # Convert image to sampled pixel list.
    $pixels = Get-ImagePixels -ReferenceFile $c -Increment 10

    # Detect mostly-grey frames (more than 50% same grey pixel name).
    $greySkull = $pixels.Pixels | Group-Object Name | Where-Object{ $_.Count -gt ($pixels.Pixels.Count * 0.50) }

    # Delete frames matching the unwanted grey pattern.
    if($greySkull) {
        Remove-Item -Path $c.FullName -Force
    }
    else{
        # Keep usable frame data for the next comparison stage.
        $pixels
    }
}
Write-Progress -Activity "Done" -Id 1 -Completed
# Show how many frames survived cleaning.
Write-Host "$($CompareCaptures.Count) => $($CleanCaptures.Count)"


# Sort remaining captures by file path/name order.
$SortedFrames = $CleanCaptures | Sort-Object Path
# Use first remaining frame as initial reference.
$ReferenceFile = $SortedFrames[0]
# Track how many near-duplicate frames are removed.
$removed = 0
for ($i = 1; $i -lt $SortedFrames.Count; $i++) {

    # Progress bar for similarity comparison loop.
    Write-Progress -Activity "$removed removed" -Status "$i compared" -PercentComplete (($i / $SortedFrames.Count) * 100) -Id 1

    # Candidate frame to compare against reference frame.
    $DifferenceFile = $SortedFrames[$i]

    # Calculate pixel difference percentage.
    $difPer = Get-PixelComparison $ReferenceFile $DifferenceFile
    
    # If almost identical (< 5%), delete the candidate frame.
    if ($difPer -lt .05) {
        Remove-Item -Path $DifferenceFile.Path -Force
        $removed++
    }
    else {
        # If different enough, make this frame the new reference.
        $ReferenceFile = $DifferenceFile
    }
}

Write-Progress -Activity "Done" -Id 1 -Completed

# Summary of duplicate-removal results.
Write-Host "$removed - frames were removed due to similarity."

Write-Host "$($SortedFrames.Count - $removed) - frames remain after removing similar frames."


# Read the final set of kept frame files.
$FinalCaptures = Get-ChildItem -Path $v.DirectoryName -Filter '*.jpg'

# Pull the frame number from filename suffix (example: _0007).
$captureNumber = $FinalCaptures[1].BaseName.Split('_')[-1]

# Convert frame number text to integer.
$captureInt = [int]$($captureNumber.TrimStart('0'))

# Convert frame index to timestamp (5 seconds per extracted frame).
$ts = New-TimeSpan -Seconds ($captureInt * 5)

# Display timestamp in HH:mm:ss format.
$ts.Hours.ToString("00") + ":" + $ts.Minutes.ToString("00") + ":" + $ts.Seconds.ToString("00")


Function Get-TimeFromCapture {
    param(
        # A frame file object whose filename contains the frame index.
        $capture
    )

    # Extract numeric suffix from capture filename.
    $captureNumber = $capture.BaseName.Split('_')[-1]

    # Convert suffix to integer index.
    $captureInt = [int]$($captureNumber.TrimStart('0'))

    # Translate index into elapsed time based on 5-second sampling interval.
    $ts = New-TimeSpan -Seconds ($captureInt * 5) # Because capture was ever 5 seconds

    # Return formatted time string for ffmpeg trimming parameters.
    $ts.Hours.ToString("00") + ":" + $ts.Minutes.ToString("00") + ":" + $ts.Seconds.ToString("00")
}

# Define trim window using first kept capture and last kept capture.
$start = Get-TimeFromCapture -capture $FinalCaptures[1]
$end = Get-TimeFromCapture -capture $FinalCaptures[-1]

# Build ffmpeg trim command (stream copy keeps this fast, no re-encode).
$trim = "ffmpeg -ss $start -to $end -i ""$($v.FullName)"" -c copy ""$($v.DirectoryName)\$($v.BaseName)_trimmed.mp4"""

# Run the final trim command.
Invoke-Expression $trim
