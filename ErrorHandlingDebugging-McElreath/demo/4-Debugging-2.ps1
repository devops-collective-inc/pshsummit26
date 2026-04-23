
function Do-Something-Else {
    param (
        [string]$param1,
        [string]$param2
    )
    $variable1 = $param1
    $variable2 = $param2
    Write-Host "Doing something with parameters: $param1, $param2"
}

Do-Something-Else -param1 "Hello" -param2 "World"