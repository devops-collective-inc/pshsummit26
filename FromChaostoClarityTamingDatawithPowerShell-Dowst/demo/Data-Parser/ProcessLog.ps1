# Load the pipeline rules
$rules = Get-Content '.\log-demo\pipeline-rules.json' -Raw | ConvertFrom-Json

# Get all files from the input folder
$files = Get-ChildItem -Path '.\log-demo\Input' -File

$results = foreach ($file in $files) {
    Write-Host "`nProcessing file: $($file.Name)" -ForegroundColor Cyan

    # Find the first rule that matches this file
    $rule = $rules.Rules | Where-Object {
        $_.Match.Extension -eq $file.Extension -and
        $file.BaseName -like "*$($_.Match.FileNamePattern)*"
    } | Select-Object -First 1

    if (-not $rule) {
        Write-Warning "No matching rule found for $($file.Name)"
        continue
    }

    Write-Host "Matched rule: $($rule.Name)" -ForegroundColor Yellow

    # Load the mapping file for this rule
    $mapping = Get-Content $rule.MappingFile -Raw | ConvertFrom-Json

    Write-Host "Using mapping file: $($rule.MappingFile)" -ForegroundColor DarkGray

    # Import the file based on the parser type
    if ($rule.Parser -eq 'DelimitedText') {
        $rows = Import-Csv -Path $file.FullName -Delimiter $mapping.Delimiter
    }
    else {
        Write-Warning "Unsupported parser type: $($rule.Parser)"
        continue
    }

    # Import Severity Map
    $severityMap = if ($mapping.ValueTransforms.Severity) {
        $severityMapPath = $mapping.ValueTransforms.Severity.MapFile
        Get-Content $severityMapPath -Raw | ConvertFrom-Json
    }

    # Normalize every row into a common shape
    foreach ($row in $rows) {
        $severity = $row.($mapping.FieldMap.Severity)

        # If there is a severity map, translate the value
        if ($severityMap) {
            $severity = $severityMap.$severity
        }

        [pscustomobject]@{
            Timestamp  = $row.($mapping.FieldMap.Timestamp)
            Host       = $row.($mapping.FieldMap.Host)
            Severity   = $severity
            Message    = $row.($mapping.FieldMap.Message)
            LogType    = $rule.Name
            SourceFile = $file.Name
        }
    }
}

# Display the normalized results
$results | Format-Table -AutoSize