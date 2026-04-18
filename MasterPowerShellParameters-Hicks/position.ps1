
Return "This is a demo script file"

Function Get-Foo {
    Param($Name,$Count,$ID)

    Write-Host "Getting $count items for $name with an id of $ID"
}

Get-Foo Fred 3 123

Function Get-Foo {
    Param(
    [Parameter(Position = 0)]
    [string]$Name,
    [Parameter(Position = 1)]
    [int]$Count,
    [int]$ID = 100
    )

    Write-Host "Getting $count items for $name with an id of $ID"
}