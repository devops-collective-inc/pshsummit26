###demo auto completion

return "This is a walk through demo"

Get-Command Register-ArgumentCompleter
help Register-ArgumentCompleter -full

#add completion to a command

Register-ArgumentCompleter -CommandName Get-WinEvent -ParameterName Logname -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    (Get-WinEvent -listlog "$wordtoComplete*").logname |
    ForEach-Object {
        # completion text,listitem text,result type,Tooltip
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Get-WinEvent -Logname <tab>

Register-ArgumentCompleter -CommandName Get-Command -ParameterName Verb -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Verb "$wordToComplete*" |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Verb, $_.Verb, 'ParameterValue', ("Group: $($_.Group)"))
    }
}

# get-command -verb [tab]

#define for a function

Function Get-ServiceStatus {
    [cmdletbinding()]
    Param([string]$Computername = $env:COMPUTERNAME)

    $p = @{
        Computername = $computername
        ClassName    = "Win32_service"
        Filter       = "StartMode ='Auto' AND State<>'Running'"

    }
    Get-CimInstance @p
}

# Get-ServiceStatus -computername [tab]

Register-ArgumentCompleter -CommandName Get-ServiceStatus -ParameterName Computername -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Content c:\scripts\company.txt | Where-Object {$_ -match "\w+"}  |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Trim(), $_.Trim(), 'ParameterValue', $_)
    }
}

# Get-ServiceStatus -computername

#or as a parameter attribute in your function
Function Get-ProcessDetail {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, Mandatory)]
        [ArgumentCompleter({(Get-Process).name})]
        [string]$Name
    )

    Get-Process -Name $name | Select-Object ID, Name, StartTime,
    @{Name = "RunTime"; Expression = {(Get-Date) - $_.starttime}},
    Path
}

Function Get-EventLogDetail {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0)]
        [ArgumentCompleter({(Get-Eventlog -List).log.foreach({"'$_'"})})]
        [string]$LogName,
        [PSCredential]$Credential
    )
    Write-Verbose "Getting $LogName"
    Write-Verbose "Using filter filename='$LogName'"
    Get-CimInstance -ClassName win32_NTEventLogFile -filter "filename='$LogName'" |
    Select-Object -Property LogFileName, Name, FileSize, MaxFileSize, LastModified, NumberOfRecords,
    @{Name = "PctUsed"; Expression = {($_.FileSize/$_.MaxFileSize)*100}}
}