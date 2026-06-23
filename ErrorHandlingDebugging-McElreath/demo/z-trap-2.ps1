
trap { 
    # Throw "An error occurred: $_" -ForegroundColor Magenta 
    Write-Host "An Error Ocurred. But I don't care. Moving on..."
}

Import-Module C:\code\summit-2026\Toolmaking\module\Summit-Toolbox\ -Force

Invoke-Nonsense -Path c:\Does-Not-Exist

Write-Host "Done"




