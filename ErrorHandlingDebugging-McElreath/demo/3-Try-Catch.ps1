
$Error.Clear()
cls


# Try/Catch Syntax
try {
    ## Try some code
} catch {
    ## Code that runs after catching Terminating Errors
} finally {
    ## Code that runs ALWAYS (success or failure)
}



# Catching a terminating Error
try {
    1/0
    Write-Host "Will this print?" -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Magenta
}


# Will this catch the error?
try {
    Get-ChildItem c:\Does-Not-Exist
    Write-Host "Will this print?" -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Magenta
}


# Forcing the catch with -ErrorAction Stop
try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
    Write-Host "Will this print?" -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Magenta
}

# Getting Error Info
$Error[0]
$Error[0] | Select-Object *

# Get the latest Error with Get-Error
Get-Error -Newest 1


$Error.Clear()
cls


try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "The item was not found." -ForegroundColor Magenta
} catch {
    Write-Host "A different error occurred: $_" -ForegroundColor Red
}


Get-Error -Newest 1

# Catch the ItemNotFoundException
try {
    Get-ChildItem C:\code -ErrorAction Stop
    1/0
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "The item was not found." -ForegroundColor Magenta
} catch {
    Write-Host "A different error occurred: $_" -ForegroundColor Red
}


# Catching multiple error types
try {
    1/0
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "The item was not found." -ForegroundColor Magenta
} catch [System.DivideByZeroException] {
    Write-Host "A divide by zero error occurred" -ForegroundColor Red
} catch {
    Write-Host "An even different error occurred: $_" -ForegroundColor DarkGreen
}


try {
    Get-ChildItem2 c:\Does-Not-Exist
} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "The item was not found." -ForegroundColor Magenta
} catch [System.DivideByZeroException] {
    Write-Host "A divide by zero error occurred" -ForegroundColor Red
} catch {
    Write-Host "An even different error occurred" -ForegroundColor DarkGreen
}


$Error.Clear()
cls


try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    throw
}

$Error[0] | Select-Object *

$Error.Clear()
cls


try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    Write-Error $_
}

$Error[0]

$Error[0] | Select-Object *


$Error.Clear()

# Throw vs. Throw "Custom Message" vs. Write-Error
try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    throw
    # throw "A custom error message"
    # Write-Error "This is a Write-Error message."
    Write-Host "Will this print?" -ForegroundColor Magenta
}

$Error[0] | Select-Object *

$Error[1] | Select-Object *


$Error.Clear()

# Throw vs. Throw "Custom Message" vs. Write-Error
try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    Write-Error "This is a Write-Error message." -ErrorAction Stop
    Write-Host "Will this print?" -ForegroundColor Magenta
}


$Error.Clear()
cls


$array = @('.\1.txt', '.\2.txt', '.\3.txt')

# Item-specific Error Messages
foreach ($file in $array) {
    try {
        Start-Sleep -Seconds 1
        Get-ChildItem -Path $file -ErrorAction Stop
    } catch {
        Write-Error "Error accessing $file : $_"
        # Throw("Error accessing $file : $_")
    }
}

$Error

$Error.Count

$Error[0]
$Error[1]


$Error.Clear()
cls

# Using the caller's ErrorActionPreference
$ErrorActionPreference = 'Inquire'

function Test-Error {
    $callerErrorActionPreference = $ErrorActionPreference
    try {
        Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction $callerErrorActionPreference
        Write-Host "Will this Print?" -ForegroundColor Magenta
    }
}

Test-Error



$ErrorActionPreference = 'Continue'


# Finally
Try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    throw "An error occurred: The specified path does not exist."
} finally {
    Write-Host "This will always execute, even if an error is thrown." -ForegroundColor Magenta
}



# Throw error with an Exception Type
Try {
    Get-ChildItem c:\Does-Not-Exist -ErrorAction Stop
} catch {
    throw [System.Management.Automation.ItemNotFoundException]::new("Custom Message")
} finally {
    Write-Host "This will always execute, even if an error is thrown." -ForegroundColor Magenta
}

$Error[0] | Select-Object *






