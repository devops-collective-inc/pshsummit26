<#
=======================
The 'Function' PSDrive
=======================

What is it: PSDrive
What it does: Designed to show any functions/filters loaded into memory

Some examples below.
#>

# ---
# List all functions/filters
Get-ChildItem -Path Function:/

# ---
# Display the definition of a function
(Get-Item Function:/prompt).Definition

# ---
# Runtime definition of a function
New-Item -Path Function:\Invoke-Hello -Value {
    param($Message)
    "Hello, $Message!"
}

# Test it
Invoke-Hello -Message 'Summit'
