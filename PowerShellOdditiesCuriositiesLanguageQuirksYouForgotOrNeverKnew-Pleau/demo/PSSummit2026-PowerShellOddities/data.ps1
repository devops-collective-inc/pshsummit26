<#
=======================
 The 'data' keyword
=======================

What is it: A keyword
What it does: It seems pretty niche, use cases primarily seem to be be localization

#>

# This will depending on the setting of $PSUICulture / Get-UICulture

# Default fallback strings (safe in all platforms) 
# (Polish)
$msg = data {
    ConvertFrom-StringData @'
Greeting = Cześć
Farewell = Do widzenia
'@
}

# Import localized data if available if a lang.psd1 is available
$importLocalizedDataParams = @{
    BindingVariable = 'msg'
    BaseDirectory   = $PSScriptRoot
    #FileName        = 'lang.psd1'
    ErrorAction     = 'SilentlyContinue'
}
Import-LocalizedData @importLocalizedDataParams

# Use the strings
$msg.Greeting
$msg.Farewell

<#
My messages are going to use the lang in my root because 
my `Get-UICulture` is set to invariant language.

data { } block          ← loaded first, always
    ↓ overwritten by
lang.psd1 (root)        ← culture-neutral fallback .psd1
    ↓ overwritten by
es-ES/lang.psd1         ← specific culture match

If I delete the root lang.psd1 you'll see it defaults back to the data

#>
