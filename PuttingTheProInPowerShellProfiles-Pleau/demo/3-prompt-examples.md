# Prompt Examples

Holy smoke stacks, are you saying I have the power to just modify `prompt`?

Yes.

---

## Plus Up your Prompt

You can do some fun things with your prompt.

```powershell
# Maybe you don't like the carrot
function prompt {'PS ~ '}

# Change our prompt, the "PS" always felt a little lame, let's personalize
function prompt {'Bobby > '}

# Maybe you want something more functional?
function prompt {"[ $(Get-Date) ] > "}

# Maybe you want some info AND personalization (no more hard-coded user)
function prompt {"[$env:USER] [ $(Get-Date) ] > "}

# Maybe you want something LESS functional?
function prompt {"$(Get-Random -InputObject '🚀','🔥','🦴','🌲','🌊','⭐','🍕','🎲','🎸','🏆') > "}
```

---

You likely noticed this from our last examples...

The `prompt` function should return a **string** or an object formatted as a **string**!
This requires the use of a sub expression `$()` in order to make it all jive.

```powershell
# BAD ❌
function prompt {"(Get-Date) > "}
# GOOD ✅
function prompt {"$(Get-Date) > "}
```

FUN FACT!

- Q: Was it interesting that `Get-Item` or `Get-Date` automatically selected a string property?
  * A: Not really that's just .Net `.ToString()` magic on a DirectoryInfo/DateTime objects!

## Make your Prompt Useful

Use your prompt to give you info, data or feedback. 

Think of your prompt as free real estate!

```powershell
function prompt {
  "$env:USER | $(Get-Date -Format 'HH:MM:ss') | $pwd > "
}

Push-Location -Path /var/log/
Pop-Location
```

Another example.

```powershell
function prompt {
    $isSuccess = $?
    $status = if ($isSuccess) { "✅" } else { "❌" }

    "$status $($PSStyle.Foreground.Cyan)$(Get-Location)$($PSStyle.Reset)> "
}
```

Let's style a bit more...
