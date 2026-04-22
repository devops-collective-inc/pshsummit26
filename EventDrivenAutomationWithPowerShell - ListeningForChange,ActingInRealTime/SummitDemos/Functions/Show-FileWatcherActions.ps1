function Show-FileWatcherActions {
@'
New-Item -Path "$env:TEMP\DemoEvents\live.txt" -ItemType File
Set-Content -Path "$env:TEMP\DemoEvents\live.txt" -Value "Hi Summit!"
Rename-Item "$env:TEMP\DemoEvents\live.txt" "$env:TEMP\DemoEvents\live2.txt"
Remove-Item "$env:TEMP\DemoEvents\live2.txt"
'@ | Write-Host -ForegroundColor Gray
}
