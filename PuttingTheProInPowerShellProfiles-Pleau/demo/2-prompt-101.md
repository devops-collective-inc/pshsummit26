# Prompt 101

Personalizing your PowerShell profile wouldn't be complete without your very own custom `prompt`.

In PowerShell the prompt is...

- ✨**A function**✨

Yup, that's it!  We know functions right?

It's a special function called `prompt`.

Take a look:

```powershell
# You can see your current prompt function
Get-Command -Name prompt

# You ever wonder where that little carrot "PS >" came from?
(Get-Command -Name prompt).ScriptBlock
```

---

## Interesting Things About the Prompt

- PowerShell includes a default prompt however you usually don't see it since it ships with one.
  * You will only see the default prompt when the prompt function:
    + Generates an error
    + Doesn't return an object
- The default prompt is `PS> ` which you can see if you set the prompt function to `$null`

```powershell
# The default prompt
function prompt {$null}
# or 
function prompt {}
```

```powershell
# The default prompt you're likely used to seeing.
function prompt {
    "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($NestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}
```

Things that change the default `prompt`:

- `$ExecutionContext` will be checked to determine if you're in DBG mode.
- `Enter-PSSession` will prepend the name of the remote computer to the `prompt`.
- `$NestedPromptLevel` opens a mini PowerShell session inside your current session
  * I've never used this but session state like variables come along into the nested prompt
    + The prompt's `>` will increment 
  * You can create one with `$Host.EnterNestedPrompt`
  * Probably most of what you'd need exists in PowerShell's native debugging

---

## Links

- [about_Prompts](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_prompts?view=powershell-7.6)

