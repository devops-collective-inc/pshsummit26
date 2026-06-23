

function Test-Error {
    param (
        [ValidateSet("Break", "Continue", "Ignore", "Stop", "SilentlyContinue", "Inquire" , "Suspend")]
        $errorAction = "Continue"
    )
    $variable1 = "Hello"
    $variable2 = "Summit 2026!"

    Get-ChildItem c:\Does-Not-Exist -ErrorAction $errorAction

    Write-Host "Will this Print?" -ForegroundColor Magenta
}


Test-Error -ErrorAction "Inquire"

Test-Error -ErrorAction "Break"



