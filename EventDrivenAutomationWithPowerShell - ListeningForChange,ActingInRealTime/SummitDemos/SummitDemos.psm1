# Import all functions from the Functions folder
$functionPath = Join-Path $PSScriptRoot 'Functions'

Get-ChildItem -Path $functionPath -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}
