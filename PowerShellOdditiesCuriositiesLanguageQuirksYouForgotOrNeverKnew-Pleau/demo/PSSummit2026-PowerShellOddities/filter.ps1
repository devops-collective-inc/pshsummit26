<#
=======================
The 'filter' keyword
=======================

What is it: Keyword
What it does: Designed to just run the process block for each object in the pipeline
Link: 

1. Lightweight function
2. No need to declare a 'process' block for pipeline objects
3. A little less syntax
#>

# ---
# Basic Example of filter

filter StartsWithA {
    if ($_ -clike "A*") {
        $_
    }
}

'Apple', 'Banana', 'Kiwi', 'Orange', 'Pear', 'Avocado' | StartsWithA

# ---
# More Practical Example

filter ErrorsOnly {
    if ($_.Status -eq "Error") {
        $_
    }
}
Import-Csv .\_logs.csv | ErrorsOnly

#vs

function Get-ErrorsOnly {
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        if ($InputObject.Status -eq "Error") {
            $InputObject
        }
    }
}
Import-Csv .\_logs.csv | Get-ErrorsOnly

# I was curious about performance
$t1 = Trace-Script -ScriptBlock {Import-Csv ./_logs.csv | ErrorsOnly}
$t2 = Trace-Script -ScriptBlock {Import-Csv .\_logs.csv | Get-ErrorsOnly}

