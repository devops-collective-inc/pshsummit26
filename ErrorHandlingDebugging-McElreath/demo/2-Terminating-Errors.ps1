
$Error.Clear()
cls


function Test-Error {
    Get-ChildItem c:\Does-Not-Exist

    Write-Host "Will this Print?" -ForegroundColor Magenta
}

Test-Error


function Test-Error {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop

    Write-Host "Will this Print?" -ForegroundColor Magenta
}

Test-Error


$ErrorActionPreference # Continue, SilentlyContinue, Ignore, Stop, Break, Inquire, Suspend


function Test-Error {
    param (
        [ValidateSet("Break", "Continue", "Ignore", "Stop", "SilentlyContinue", "Inquire" , "Suspend")]
        $errorAction = "Continue"
    )
    $variable1 = "Hello"; $variable2 = "Summit 2026!"

    Get-ChildItem c:\Does-Not-Exist -ErrorAction $errorAction

    Write-Host "Will this Print?" -ForegroundColor Magenta
}

Test-Error

Test-Error -ErrorAction "Stop"
Test-Error -ErrorAction "SilentlyContinue"
Test-Error -ErrorAction "Ignore" # Does not add an error record to the $Error variable
Test-Error -ErrorAction "Suspend" # Only used in PowerShell Workflows
Test-Error -ErrorAction "Inquire"
Test-Error -ErrorAction "Break"



function Test-Error {
    $ErrorActionPreference = "Stop"
    
    Get-ChildItem c:\Does-Not-Exist

    Write-Host "This will not be printed because ErrorActionPreference is set to Stop" -ForegroundColor Magenta
}

Test-Error


function Test-Error {
    throw("An error occurred in Test-Error")

    Write-Host "This will not be printed after a throw statement" -ForegroundColor Magenta
}

Test-Error



$Error.Clear()
$Error
cls

function Test-Error {
    $ErrorActionPreference = "SilentlyContinue"
    
    Get-ChildItem c:\Does-Not-Exist

    Write-Host "This will be printed because ErrorActionPreference is set to SilentlyContinue" -ForegroundColor Magenta
}

Test-Error

$Error