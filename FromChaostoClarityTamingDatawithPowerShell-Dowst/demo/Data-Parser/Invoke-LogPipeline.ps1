[CmdletBinding()]
param(
    [string]$InputPath = '.\log-demo\Input',

    [string]$RulesPath = '.\log-demo\pipeline-rules.json',

    [string]$OutputPath = '.\log-demo\Output\normalized-logs.csv'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function Resolve-RelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$ChildPath
    )

    if ([System.IO.Path]::IsPathRooted($ChildPath)) {
        return $ChildPath
    }

    $baseFolder = Split-Path -Path $BasePath -Parent
    return (Join-Path -Path $baseFolder -ChildPath $ChildPath)
}

function Get-MatchingRule {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [object[]]$Rules
    )

    foreach ($rule in $Rules) {
        $extensionMatches = $File.Extension -eq $rule.Match.Extension
        $nameMatches = $File.BaseName -match $rule.Match.FileNamePattern

        if ($extensionMatches -and $nameMatches) {
            return $rule
        }
    }

    return $null
}

function Get-TransformMap {
    param(
        [Parameter(Mandatory)]
        [string]$MappingFilePath,

        [Parameter(Mandatory)]
        [pscustomobject]$TransformDefinition
    )

    if ($TransformDefinition.Type -ne 'Map') {
        throw "Unsupported transform type '$($TransformDefinition.Type)' in $MappingFilePath"
    }

    $mapPath = Resolve-RelativePath -BasePath $MappingFilePath -ChildPath $TransformDefinition.MapFile
    return Read-JsonFile -Path $mapPath
}

function Convert-RecordToNormalizedObject {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Record,

        [Parameter(Mandatory)]
        [pscustomobject]$Rule,

        [Parameter(Mandatory)]
        [string]$MappingFilePath,

        [Parameter(Mandatory)]
        [pscustomobject]$Mapping,

        [Parameter(Mandatory)]
        [string]$SourceFile
    )

    $normalized = [ordered]@{}

    foreach ($targetField in $Mapping.FieldMap.PSObject.Properties.Name) {
        $sourceField = $Mapping.FieldMap.$targetField
        $value = $Record.$sourceField

        if ($Mapping.ValueTransforms -and $Mapping.ValueTransforms.PSObject.Properties.Name -contains $targetField) {
            $transform = $Mapping.ValueTransforms.$targetField

            switch ($transform.Type) {
                'Map' {
                    $lookup = Get-TransformMap -MappingFilePath $MappingFilePath -TransformDefinition $transform
                    $lookupKey = [string]$value
                    if ($lookup.PSObject.Properties.Name -contains $lookupKey) {
                        $value = $lookup.$lookupKey
                    }
                }
                default {
                    throw "Unsupported transform type '$($transform.Type)' in $MappingFilePath"
                }
            }
        }

        $normalized[$targetField] = $value
    }

    $normalized['LogType'] = $Rule.LogType
    $normalized['RuleName'] = $Rule.Name
    $normalized['SourceFile'] = [System.IO.Path]::GetFileName($SourceFile)

    [pscustomobject]$normalized
}

function Import-LogFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [pscustomobject]$Rule,

        [Parameter(Mandatory)]
        [string]$RulesPath
    )

    $mappingFilePath = Resolve-RelativePath -BasePath $resolvedRulesPath -ChildPath $Rule.MappingFile
    $mapping = Read-JsonFile -Path $mappingFilePath

    switch ($Rule.Parser) {
        'DelimitedText' {
            $records = Import-Csv -Path $FilePath -Delimiter $mapping.Delimiter
        }
        default {
            throw "Unsupported parser '$($Rule.Parser)' for rule '$($Rule.Name)'"
        }
    }

    foreach ($record in $records) {
        Convert-RecordToNormalizedObject -Record $record -Rule $Rule -MappingFilePath $mappingFilePath -Mapping $mapping -SourceFile $FilePath
    }
}

$resolvedRulesPath = (Resolve-Path -Path $RulesPath).Path
$rulesConfig = Read-JsonFile -Path $resolvedRulesPath
$inputFiles = Get-ChildItem -Path $InputPath -File

$results = foreach ($file in $inputFiles) {
    $rule = Get-MatchingRule -File $file -Rules $rulesConfig.Rules

    if (-not $rule) {
        Write-Warning "No matching rule found for file '$($file.Name)'"
        continue
    }

    Write-Host "Processing $($file.Name) with rule $($rule.Name)" -ForegroundColor Cyan
    Import-LogFile -FilePath $file.FullName -Rule $rule -RulesPath $resolvedRulesPath
}

$results | Format-Table -AutoSize

$outputFolder = Split-Path -Path $OutputPath -Parent
if ($outputFolder -and -not (Test-Path -Path $outputFolder)) {
    $null = New-Item -Path $outputFolder -ItemType Directory -Force
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "`nNormalized output exported to $OutputPath" -ForegroundColor Green