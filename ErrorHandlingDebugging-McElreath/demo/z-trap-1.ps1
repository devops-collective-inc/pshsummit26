
trap { throw "An error occurred: $_" }

Get-ChildItem -Path "C:\NonExistentDirectory" -ErrorAction Stop

Write-Host "Done"