<#
=======================
 The $ExecutionContext automatic variable
=======================

What is it: Automatic Variable
What it does: Gives access to internal environment information of current PowerShell session
              This comes primarily from the 'EngineIntrinsics' object.

Some uses are below but there are a lot more you can do with this variable!

#>

# ---
# Lots of data in here
$ExecutionContext
$ExecutionContext.SessionState

# ---
# Host environment information, good for coding against different host types VS Code vs ISE
$ExecutionContext.Host
$ExecutionContext.Host.Name

# ---
# Here it is used in the prompt you look at all the time
# This is the out of the box PowerShell prompt you see.
function prompt {
    "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($NestedPromptLevel + 1)) "
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}

# ---
# Doing bad things.. um I mean Red/Purple team activities
# Security tools can sometimes miss alternative ways to run things
$ExecutionContext.InvokeCommand.InvokeScript("Get-Process")
