# Profile Examples

Lets make some changes to our profile script.

---

## Where to Begin

I'm sure you have some helper functions or other scripts you've written?

Load them in!

---

## Something Simple

Maybe you want to change PowerShell's error view behavior?

```powershell
# Error as default concise view
Get-Item -Path /not/a/real/path
```

Our profile update:

```powershell
$ErrorView = 'NormalView'
```

WOW. Many Error. So Detail.
(The mad lads can also do `DetailView`)

```powershell
# Error as default concise view
Get-Item -Path /not/a/real/path
```

---

## Custom Functions or Aliases

- Why isn't there an alias for `ConvertFrom-Json`?
- Why is it annoying to see your git remote URLs?

Fix it with your profile!

NOTE: `New-Alias` should use `-Force` to avoid errors.

```PowerShell
New-Alias -Name cfj -Value ConvertFrom-Json -Force

function Get-GitRemote {
    git remote -v
}
# Let's even add an alias for our custom helper function
New-Alias -Name ggr -Value Get-GitRemote -Force
```

Test out our new stuff, don't forget to reload your profile `. $PROFILE` !!

```powershell
Push-Location -Path ~/code/git/PSSummit2026-PSProfiles/
cat ./_data.json | cfj

ggr
Pop-Location
```

---

## PSReadline Settings

I like my PSReadline configured a certain way.

```powershell
# PSReadline Helper
function OnViModeChange {
    if ($args[0] -eq 'Command') {
        # VISUAL MODE - Set the cursor to a blinking block.
        Write-Host -NoNewline "`e[1 q"
    } else {
        # INSERT MODE - Set the cursor to a blinking line.
        Write-Host -NoNewline "`e[5 q"
    }
}

# Splat my PSReadline Options
$setPSReadLineOptionParams = @{
    PredictionSource = "History"
    PredictionViewStyle = "ListView"
    HistoryNoDuplicates = $true
    EditMode = "Vi"
    ViModeIndicator  = "Script"
    ViModeChangeHandler = $Function:OnViModeChange
    Colors = @{
        ListPrediction = '#9800f2'
    }
}
Set-PSReadLineOption @setPSReadLineOptionParams

# Where-Object helper
Set-PSReadLineKeyHandler -Chord Ctrl+w -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('| Where-Object -FilterScript {$_.')
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('}')
    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar()
}

# Select-Object helper
Set-PSReadLineKeyHandler -Chord Ctrl+s -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('| Select-Object -Property ')
}
```

Hopefully this is starting to show you the kind of things you can do!
