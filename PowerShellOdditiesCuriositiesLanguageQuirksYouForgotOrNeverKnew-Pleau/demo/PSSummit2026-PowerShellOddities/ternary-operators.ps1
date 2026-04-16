<#
=======================
The Ternary Operator 
=======================

What is it: Operator
What it does: Replaces if-else 
Link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.6#ternary-operator--if-true--if-false

Simple breakdown
<condition> ? <if-true> : <if-false>

Some examples below.
#>

# ---
# Setting a default value
$inputName = ""
$name = ($inputName -ne "") ? $inputName : "Guest"
$name

# ---
# Path checking message
$path = '/home'

$message = (Test-Path $path) ? "Path Exists." : "Path not found!"
$message

#vs

if (Test‑Path $path) {
    $message = "Path exists."
} else {
    $message = "Path not found!"
}
