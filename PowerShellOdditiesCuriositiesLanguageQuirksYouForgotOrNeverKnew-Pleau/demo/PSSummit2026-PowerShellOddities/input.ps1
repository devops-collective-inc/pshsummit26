<#
=======================
The 'input' Automatic Variable
=======================

What is it: Automatic Variable
What it does: An enumerator for input passed to a function.
              It's only available to functions.
              In 'begin' it has no data
              In 'process' it contains the current object on the pipeline
              In 'end' it enumerates the collection of all input for the function
              You *can't* use it both in 'process' and 'end'
              It is also available in the -Command param for pwsh
Link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.6#input

What it does again: The most ANNOYING automatic variable ever.

Some examples below.
#>

# ---
# Using it
function ConvertTo-StringUpper {
    foreach ($item in $input) {
        $item.ToUpper()
    }
}
"apple", "banana", "cherry" | ConvertTo-StringUpper
