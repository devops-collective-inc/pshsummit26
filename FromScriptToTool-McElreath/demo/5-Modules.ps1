#########################
## using Modules:
#########################

# Import the module
Import-Module .\module\Summit-Toolbox\ -Force

# Get all commands available in the module
Get-Command -Module Summit-Toolbox

# Run one of the commands
Get-SummitGreeting

# Get help documentation of a command
Get-Help Update-SummitService 

# Running module commands
Update-SummitService -ServiceName bits -Action Get 

Update-SummitService -ServiceName bits -Action Start 

Update-SummitService -ServiceName bits -Action Stop 

Update-SummitService -ServiceName bits -Action Restart 

Get-BasicCommand -CommandName "Testing 123"