# Oh My Posh

Oh My Posh is a prompt engine.

A.K.A. it makes customizing your prompt easier than building your own.

- Works with:
  * Standard Terminal
  * Windows Terminal
  * Every Linux Terminal I have used so far (kitty, ghostty, etc)

- `oh-my-posh` themes are built out of _.json_ files.
  * specifically _*.omp.json_ files.

It took me 2 years to realize 'omp' just meant oh-my-posh.......

---

## Install oh-my-posh

- Install Docs
  * [Linux](https://ohmyposh.dev/docs/installation/linux)
    + Manual (install script)
    + Possibly via package manager (distro dependent)
  * [MacOS](https://ohmyposh.dev/docs/installation/macos)
    + brew
    + MacPort
  * [Windows](https://ohmyposh.dev/docs/installation/windows)
    + Chocolatey
    + Winget
    + Manual (install script)

On Linux I just used the install script: 

```bash
curl -s https://ohmyposh.dev/install.sh | sudo bash -s
```

---

## What Themes Exist?

You may not want to configure a theme from scratch.
There are TONS of pre-made ones that look great.

```powershell
# Check em' out!
$repo = "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes"
$themes = (Invoke-RestMethod $repo | Where-Object { $_.name -like "*.omp.json" }).name

foreach ($theme in $themes) {
    "`n===== $theme ====="
    $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme"
   
    # Preview prompt
    oh-my-posh print preview --config $url
    Start-Sleep -Milliseconds 250
}
```

## Set a Theme

```powershell
# Let's use the "night-owl" theme
$themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/night-owl.omp.json"
oh-my-posh print preview --config $themeUrl
```

Looks good, lets go with it!

```powershell
$themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/night-owl.omp.json"
# Let's use the "night-owl" theme
oh-my-posh init pwsh --config $themeUrl | Invoke-Expression
```

Note we're running this based on the URL so far.

Let's download a theme and run it locally in case we don't have internet.
I like a simple 1 line theme, let's grab jblab_2021

```powershell
# Run our jblab_2021 theme from our machine
Push-Location -Path ./code/git/PSSummit2026-PSProfiles/omp_themes/
$themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jblab_2021.omp.json"
Invoke-WebRequest -Uri $themeUrl -OutFile 'jblab_2021.omp.json'
oh-my-posh init pwsh --config ./jblab_2021.omp.json | Invoke-Expression

Pop-Location
```

## Add to Profile

Let's add it to our profile so it always runs!

`nvim profile`

```powershell
# Lets store our themes path in a variable
$themesPath = "$HOME/code/git/PSSummit2026-PSProfiles/omp_themes/"
oh-my-posh init pwsh --config "$themesPath/jblab_2021.omp.json" | Invoke-Expression
```


