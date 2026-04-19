Function Get-ImagePixels {
    param(
        # Full path to the image file we want to sample.
        [ValidateScript({ Test-Path $_ })]    
        [string]$ReferenceFile,
        # Pixel step size. Example: 10 means read every 10th pixel on X/Y.
        [int]$Increment
    )
    
    # Load the image into memory as a Bitmap so we can read pixel colors.
    $ReferenceImage = [System.Drawing.Bitmap]::FromFile($ReferenceFile)
   
    # Build a flat list of sampled pixels by scanning rows (Y) and columns (X).
    # Using an increment keeps processing fast for large images.
    $Pixels = for ($y = 0; $y -lt $ReferenceImage.Height; $y += $Increment) {
        for ($x = 0; $x -lt $ReferenceImage.Width; $x += $Increment) {
            # Get the Color object at this coordinate.
            $ReferenceImage.GetPixel($x, $y);
        }
    }

    # Return metadata + sampled pixels as one object for later comparison.
    [pscustomobject]@{
        Path   = $ReferenceFile
        Width  = $ReferenceImage.Width
        Height = $ReferenceImage.Height
        Pixels = $Pixels
    }

    # Release the file handle/memory used by the bitmap.
    $ReferenceImage.Dispose()
}

Function Get-PixelComparison {
    param(
        # Object returned by Get-ImagePixels for the reference image.
        $Reference,
        # Object returned by Get-ImagePixels for the candidate image.
        $Difference
    )

    # Running total of channel differences (R + G + B across sampled pixels).
    [float]$DifferenceMeasure = 0;

    # If sample counts differ, the images are not directly comparable.
    if ($Reference.Pixels.Count -ne $Difference.Pixels.Count) {
        Write-Host "Images are of different sizes"
        # Force a high difference value to indicate mismatch.
        $DifferenceMeasure = 100
    }
    else {
        # Compare each sampled pixel from both images.
        for ($y = 0; $y -lt $Reference.Pixels.Count; $y++) {
            # Calculate absolute difference per color channel.
            $DifferenceMeasure += [System.Math]::Abs($Reference.Pixels[$y].R - $Difference.Pixels[$y].R);
            $DifferenceMeasure += [System.Math]::Abs($Reference.Pixels[$y].G - $Difference.Pixels[$y].G);
            $DifferenceMeasure += [System.Math]::Abs($Reference.Pixels[$y].B - $Difference.Pixels[$y].B);
        }

        # Convert accumulated channel difference into a percentage.
        # This is the orginal code, but it broken down step-by-step below
        <#
        $DifferenceMeasure = $(100 * ($DifferenceMeasure / 255) / ($Reference.Width * $Reference.Height * 3))
        #>
        
        # RGB values range from 0 to 255, so 255 is max per channel.
        $Step1 = $DifferenceMeasure / 255

        # Total channel comparisons = pixel count * 3 channels.
        $Step2 = ($Reference.Width * $Reference.Height * 3)

        # Fractional difference from 0 to 1.
        $Step3 = $Step1 / $Step2

        # Convert fraction to percent.
        $Step4 = $Step3 * 100

        # Final percentage difference used by the caller.
        $DifferenceMeasure = $Step4
    }
    
    # Output numeric difference value.
    $DifferenceMeasure
}


# 1) Gather all JPG photos and sort by file size.
# Sorting by length helps us pre-group likely similar photos quickly.
$photos = Get-ChildItem -Path '.\Photos' -Filter '*.jpg' | Sort-Object Length

# Group files based on relative size. This allows for file with the same image but different meta-data to still be grouped together
# Max allowed relative file-size difference inside a group (2%).
$threshold = 0.02
# Array of groups, where each group is an array of FileInfo objects.
$groups = @()
# Temporary group we are currently building.
$currentGroup = @()

# 2) Group nearby file sizes together before expensive pixel checks.
foreach ($photo in $photos) {
    # Start first group with the first photo.
    if ($currentGroup.Count -eq 0) {
        $currentGroup += $photo
        continue
    }

    # Compare this photo size to the first photo in the current group.
    $baseSize = $currentGroup[0].Length
    # Relative difference lets this work across small and large files.
    $diff = [math]::Abs($photo.Length - $baseSize) / $baseSize

    # Keep photo in group if within threshold; otherwise start a new group.
    if ($diff -le $threshold) {
        $currentGroup += $photo
    }
    else {
        # Save completed group, then begin a new one with current photo.
        $groups += , $currentGroup
        $currentGroup = @($photo)
    }
}

# Add final in-progress group after loop ends.
if ($currentGroup.Count -gt 0) {
    $groups += , $currentGroup
}

# 3) Display grouping results so you can see candidates before comparison.
$i = 1
foreach ($group in $groups) {
    Write-Host "`nGroup $i"
    # Format-Table output is converted to text for cleaner Write-Host display.
    Write-Host "$(($group | Select-Object Name, Length | Format-Table | Out-String).Trim())"
    $i++
}


# 4) Compare images within each group using sampled pixel differences.
$Comparisons = @()
# Only compare groups with at least 2 photos.
foreach ($group in $groups | Where-Object { $_.Count -gt 1 }) {
    # Use the first photo in group as the baseline reference.
    $reference = Get-ImagePixels -ReferenceFile $group[0].FullName -Increment 10

    # Compare every other photo in group against the reference.
    for ($j = 1; $j -lt $group.Count; $j++) {
        $difference = Get-ImagePixels -ReferenceFile $group[$j].FullName -Increment 10
        $differencePercentage = Get-PixelComparison -Reference $reference -Difference $difference
        Write-Host "Comparing '$($group[0].Name)' with '$($group[$j].Name)': Difference = $differencePercentage%"

        # Store each comparison result for final summary output.
        $Comparisons += [PSCustomObject]@{
            Reference  = $reference.Path
            Match      = $difference.Path
            Difference = $differencePercentage
        }
    }
}

# 5) Print all comparisons as a table.
$Comparisons | Format-Table