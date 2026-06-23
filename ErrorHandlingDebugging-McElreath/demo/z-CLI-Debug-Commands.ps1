
# Using Wait-Debugger to pause execution until a debugger is attached
.\z-CLI-Debug-Script.ps1



# Create a breakpoint on line 4 of the script
$breakPoint = Set-PSBreakpoint -Script ".\z-CLI-Debug-Script.ps1" -Line 4
$breakPoint



# List all breakpoints to verify it was set
Get-PSBreakpoint -Script ".\z-CLI-Debug-Script.ps1"


$ErrorActionPreference = 'break'


.\z-CLI-Debug-Script.ps1

$ErrorActionPreference = 'Continue'

# Remove the breakpoint
Remove-PSBreakpoint -Breakpoint $breakpoint

Get-PSBreakpoint -Script ".\z-CLI-Debug-Script.ps1"
