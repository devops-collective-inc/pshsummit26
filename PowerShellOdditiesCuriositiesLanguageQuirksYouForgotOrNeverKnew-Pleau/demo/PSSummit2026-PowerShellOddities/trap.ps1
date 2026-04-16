<#
=======================
 The `trap` keyword
=======================

What is it: keyword
What it does: Catches terminating errors in the CURRENT SCOPE
              and Child scopes
Link: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_trap?view=powershell-7.5

Some uses are below but there are a lot more you can do with this variable!

#>

# Catches terminating errors in the
# current scope (and child scopes)
function Invoke-TrapExample {
    trap [System.DivideByZeroException] {
        Write-Warning "Divide by zero!"
        continue  # resume after error
        # 'break' would re-throw instead
    }
    trap {
        Write-Error "Unhandled: $_"
        break
    }

    1 / 0          # hits typed trap above
    Write-Host "After error"  # runs (continue)
    throw "boom"   # hits generic trap
}

function Invoke-TryCatchExample {
    # Catches terminating errors within the try { } block only
    try {
        1 / 0
        "Never reached"
    } catch [System.DivideByZeroException] {
        Write-Warning "Divide by zero!"
    } catch {
        Write-Error "Unhandled: $_"
    } finally {
        # Always runs — cleanup here
        Write-Host "Done"
    }
}

Invoke-TrapExample

Invoke-TryCatchExample
