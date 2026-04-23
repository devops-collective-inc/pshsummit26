
Import-Module C:\code\summit-2026\Toolmaking\module\Summit-Toolbox\ -Force

$serviceName = "bits"
$action = "Restart"


Update-SummitService -ServiceName $serviceName -Action $action

Write-Host "Done"


