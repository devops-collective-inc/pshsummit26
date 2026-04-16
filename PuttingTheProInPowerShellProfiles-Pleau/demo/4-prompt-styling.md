# Prompt Styling

Info is nice, but sometimes info is better presented.  

Let's add some color and style!

---

## `$PSStyle`

This automatic variable was introduced in PowerShell 7.2

```powershell
# See what's available in $PSStyle
$PSStyle

# You can still go old-school but you don't have to
"`e[91mTEST RED TEXT"

# You need to reset
"`e[0m"
# or 
$PSStyle.Reset
```

---

## Color

Let's create a 2 part prompt for time and the $PWD.

```powershell
$ansiColorTime = $PSStyle.Background.FromRgb(118, 0, 255)
$ansiColorPwd = $PSStyle.Background.FromRgb(255, 193, 0)

$ansiReset = $PSStyle.Reset

function prompt {
    # Get current time
    $time = Get-Date -Format "HH:mm:ss"

    # Get current directory
    $pwd = (Get-Location)

    # Build prompt string
    "$ansiColorTime[$time] $ansiColorPwd$pwd$ansiReset`n> "
}
```

Oh no... The text needs help...

---

Let's clean it up by specifying 'Foreground' and 'Background' colors.

```powershell
$ansiColorBgTime = $PSStyle.Background.FromRgb(118, 0, 255)
$ansiColorFgTime = $PSStyle.Foreground.White

$ansiColorBgPwd = $PSStyle.Background.FromRgb(255, 193, 0)
$ansiColorFgPwd = $PSStyle.Foreground.Black

$ansiReset = $PSStyle.Reset

function prompt {
    # Get current time
    $time = Get-Date -Format "HH:mm:ss"

    # Get current directory
    $pwd = (Get-Location)

    # Build prompt string
    "$ansiColorFgTime$ansiColorBgTime[$time]" +
    "$ansiColorFgPwd$ansiColorBgPwd$pwd" +
    "$ansiReset`n> "
}
```

---

## Transitions (Style)

You can use simple characters on your keyboard such as:

- `>`
- `|`
- `]`
- `}`
- `D`

```powershell
function prompt {"$env:USER | $(Get-Item -Path .) > "}
```

BUT......

If you want _REALLY_ cool transitions you'll need a nerd font!
You _could_ have this instead!

- ``
- ``
- ``
- ``
- ``
- ``
- ``
- ``

What's a nerd font??? 
From the site:

- [Nerd Fonts](https://www.nerdfonts.com/)

> Nerd Fonts patches developer targeted fonts with a high number of glyphs (icons). 
> Specifically to add a high number of extra glyphs from popular ‘iconic fonts’ such as Font Awesome, Devicons, Octicons, and others.

```powershell
$ansiColorBgTime = $PSStyle.Background.FromRgb(118, 0, 255)
$ansiColorFgTime = $PSStyle.Foreground.White

$ansiColorBgPwd = $PSStyle.Background.FromRgb(255, 193, 0)
$ansiColorFgPwd = $PSStyle.Foreground.Black

# Correct transition for  (time -> pwd)
# fg = time bg (purple), bg = pwd bg (yellow)
$ansiSeparator = $PSStyle.Foreground.FromRgb(118, 0, 255) + $PSStyle.Background.FromRgb(255, 193, 0)

# End transition (pwd -> terminal)
# fg = pwd bg (yellow), bg = default (via reset BEFORE applying fg)
$ansiEnd = $PSStyle.Foreground.FromRgb(255, 193, 0)

$ansiReset = $PSStyle.Reset

function prompt {
    $time = Get-Date -Format "HH:mm:ss"
    $pwd = Get-Location

    "$ansiColorFgTime$ansiColorBgTime[$time]" +
    "$ansiSeparator" +
    "$ansiColorFgPwd$ansiColorBgPwd$pwd" +
    "$ansiReset$ansiEnd" +
    "$ansiReset "
}
```

While doable the building and maintenance of this feels... 
            ...hard to sustain.

(WARN AUDIENCE ABOUT HOW STUBBORN I WAS IN THE PAST!)

There are tools to help!

---

## Links

- [about_ANSI_Terminals](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ansi_terminals?view=powershell-7.5)
- [Nerd Fonts](https://www.nerdfonts.com/)
