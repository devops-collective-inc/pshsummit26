
$Error.Clear()

# Let's Generate some errors
1/0
Get-ChildItem c:\Does-Not-Exist
Get-WrongCommand

# Returns an array of error records, with the most recent error at index 0
$Error

# Most recent error
$Error[0]

# The oldest error
$Error[-1]

# Can be used in a catch block to get the current error
$_

try {
    1/0
} catch {
    Write-Host "An error occurred: $_"
}

# Was the last command successful?
Get-WrongCommand
$?

# Clear the error variable
$Error.Clear()
$Error

# Generate some more errors
Get-ChildItem c:\Does-Not-Exist

# Error view options
$ErrorView # ConciseView, CategoryView, DetailedView, NormalView 

$ErrorView = 'DetailedView'

Get-ChildItem c:\Does-Not-Exist


$ErrorView = 'ConciseView'


# Get error details
$Error[0]

$Error[0] | Select-Object *

# Get the most recent error record with more information
Get-Error -Newest 1

# Get a text dump of the most recent error record
$Error[0] | Format-Custom -Force


$Error[0] | Select-Object *

$Error[0].Exception
$Error[0].InvocationInfo 
$Error[0].ScriptStackTrace
$Error[0].Exception.StackTrace




$Error.Clear()
cls

# ScriptStackTrace example
function Trace-Test {
    function Get-BadPath  { Get-ChildItem c:\Does-Not-Exist }

    function Function1 { Get-BadPath }

    function Function2 { Function1 }

    function Function3 { Function2 }

    Function3

}

Trace-Test

$error[0] | Select-Object *

