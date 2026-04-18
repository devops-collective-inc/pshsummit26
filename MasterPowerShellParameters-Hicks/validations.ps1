
[ValidateNotNullOrEmpty()]$param = "foo"
$param
$param = $null

pause

[ValidateRange(1,10)]$Count = 3
$count
$Count = 30

Pause

#must be static set
[ValidateSet("John","Paul","George","Ringo")]$Name = "Paul"
$Name = "jeff"
#automatic tab-completion

pause
#Can also define a class
Class FileExtension : System.Management.Automation.IValidateSetValuesGenerator {
    #there no class properties
    #the GetValidValues method has no parameters
    [string[]] GetValidValues() {
        #the script block contains the code to generate the valid values
        #I'm defining the array of valid values here
        $FileExtension = @('ps1', 'ps1xml', 'txt', 'json', 'xml', 'yml', 'zip', 'md', 'csv')
        #you must use the return keyword
        return [string[]] $FileExtension
    }
}

#not an ENUM
$fe = [fileExtension]::new()
$fe.GetValidValues()

Pause
Function Measure-FileExtension {
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = 'Enter the path to analyze')]
        [string]$Path = '.',
        [ValidateSet([FileExtension],ErrorMessage = "{0} is not a valid extension")]
        [string]$Extension = 'ps1',
        [switch]$Recurse
    )

    $stats = Get-ChildItem -File -Path $Path -Filter "*.$Extension" -Recurse:$Recurse |
    Measure-Object -Property Length -Sum -Average -Maximum -Minimum

    [PSCustomObject]@{
        PSTypeName = 'FileExtensionStats'
        Path       = Convert-Path $Path
        Extension  = $Extension
        Files      = $stats.Count
        TotalSize  = $stats.Sum
        Average    = $stats.Average
    }
}

Pause
Function Invoke-Test {
    [cmdletbinding()]
    Param(
        [ValidatePattern("\d{4}",ErrorMessage = "{0} does not match the expected pattern of 4 digits.")]$Value = 1000
    )

    $value
}

Invoke-Test 123

pause

Function Invoke-Test {
    [cmdletbinding()]
    Param(
        [ValidateScript({ (Get-Verb).verb -contains $_},ErrorMessage = "The value {0} is not a valid command verb.")]$Verb = "Get"
    )

    "Using verb $verb"
}
Invoke-Test
Invoke-Test jump