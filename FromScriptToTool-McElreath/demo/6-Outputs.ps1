
# Write-Host vs. Write-Output
function Get-Stuff {
    Write-Host "`nGetting some stuff..." -ForegroundColor Magenta
    Write-Output "Name: Summit-2026, Location: Bellevue, WA, Version: 1.0"
}

Get-Stuff

$variable = Get-Stuff
$variable

$variable | Get-Member


# JSON Output
function Get-Stuff {
    $hashTable = @{
        "Name" = "Summit-2026"
        "Location" = "Bellevue, WA"
        "Version" = "1.0"
    }
    Write-Output $hashTable | ConvertTo-Json
}

Get-Stuff

Get-Stuff | Get-Member

Get-Stuff | ConvertFrom-Json

# Hashtable output
function Get-Stuff {
    $hashTable = [Ordered]@{
        "Name" = "Summit-2026"
        "Location" = "Bellevue, WA"
        "Version" = "1.0"
    }
    Write-Output $hashTable
}

Get-Stuff

Get-Stuff | Get-Member

# PSCustomObject output 
function Get-Stuff {
    $object = [PSCustomObject]@{
        "Name" = "Summit-2026"
        "Location" = "Bellevue, WA"
        "Version" = "1.0"
    }
    Write-Output $object
}

Get-Stuff

Get-Stuff | Get-Member

Get-ChildItem ./1-Command-Line.ps1 | Get-Member


# Using other PS Objects as outputs
function Get-Stuff {
    $services = Get-Service BITS, WinRM, W32Time, Spooler

    $runningServices = $services | Where-Object Status -eq "Running"

    Write-Output $runningServices
}

Get-Stuff

Get-Stuff | Get-Member



function Get-Stuff {
    $services = Get-Service BITS, WinRM, W32Time, Spooler

    $runningServices = $services | Where-Object Status -eq "Running"

    $object = [PSCustomObject]@{
        "RunningServices" = $runningServices
    }

    Write-Output $object
}

Get-Stuff

Get-Stuff | Get-Member

Get-Stuff | Select-Object -ExpandProperty RunningServices | Get-Member

$services = Get-Stuff | Select-Object -ExpandProperty RunningServices
$services | Get-Service