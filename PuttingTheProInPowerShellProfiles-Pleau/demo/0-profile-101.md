# Profile 101

A PowerShell Profile is...

- ✨**A script.**✨

It's a script that runs when PowerShell starts.

A PowerShell profile can essentially do anything you can script.

Common things include:

- Alias creation
- Function or Module loading
- Execution of other scripts/commands
- Prompt modification

---

## What's a 'Profile' in PowerShell?

It's a _.ps1_ file that can live in a number of locations.  

The `$PROFILE` variable is an automatic variable that contains: 

- The path to the current profile (CurrentUserCurrentHost) `$PROFILE`
- The possible profile paths loaded in session, e.g. `$PROFILE.CurrentUserCurrentHost`
  * These are order specific and run in the order you see below!!!
 
```powershell
# Current user, current host
$PROFILE

$PROFILE | Select-Object -Property *

# Today we're mostly talking about CurrentUserCurrentHost
$PROFILE
#or
$PROFILE.CurrentUserCurrentHost
```

Note:

- The path values will change depending on the OS
- _'Host'_ is effectively where PowerShell is running.
  * The path values can change for certain tools (i.e. VS Code Terminal)

Regarding the other profile paths.
There may be a time you want a profile to load for all users such as:

- Shared servers, terminal servers, job servers
- Prank your co-workers

The actual profile file we're going to focus on is:

 - *Microsoft.PowerShell_profile.ps1*

THIS WON'T EXIST YET BY DEFAULT!  YOU NEED TO CREATE THE FILE!

```powershell
# Doesn't exist yet
Get-Item -Path $PROFILE

if (-not (Test-Path -Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force
}
Set-Location -Path (Get-Item -Path $PROFILE).Directory

bat $PROFILE
```

---

## pwsh -NoProfile

You can launch PowerShell without loading your profile.  This is great for:

- Non-interactive scripts that you may want to load faster
- Scheduled things like a cron job or Windows scheduled task

```powershell
# Run PowerShell with no profile
pwsh -nop
# Or for the lovers of verbosity
pwsh -NoProfile
```

---

## What Next?

We have a file but what do we do next?

What do you want your profile to do?  Lets add some things!

```powershell
nvim $PROFILE

'Hello Bobby!'
"You're current path: {0}" -f (Get-Location).Path


bat $PROFILE
```

We can reload the profile by dot sourcing our _$PROFILE_.
Remember, it's just **a script**!

You can also re-launch PowerShell or launch a new instance.
If your profile is doing anything with state or one time runs this may be cleaner.

---

## Links

[about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.6)
