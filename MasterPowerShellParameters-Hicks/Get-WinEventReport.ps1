#requires -version 7.2
#requires -module ThreadJob

if ($IsLinux -OR $IsMacOS) {
    Return "$($PSStyle.foreground.red)This command requires a Windows platform.$($PSStyle.Reset)"
}
Function Get-WinEventReport {
    [cmdletbinding()]
    [alias('wer')]
    [outputType('WinEventReport')]
    Param(
[Parameter(
    Position = 0,
    Mandatory,
    ValueFromPipelineByPropertyName,
    HelpMessage = 'Specify the name of an event log like System.'
)]
[ValidateNotNullOrEmpty()]
[ArgumentCompleter({
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    #cache results to a global variable
    if ($global:CompletionResults.Count -eq 0) {
        $global:CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        (Get-WinEvent -ListLog *$wordToComplete*).LogName.Foreach({
            # CompletionText,ListItemText,ResultType,ToolTip
            $global:CompletionResults.add($([System.Management.Automation.CompletionResult]::new("'$($_)'", $_, 'ParameterValue', $_)  ))
        })
    }
    return $global:CompletionResults
})]
[string]$LogName,

        [Parameter(HelpMessage = 'Specifies the maximum number of events that are returned. Enter an integer such as 100. The default is to return
        all the events in the logs or files.')]
        [Int64]$MaxEvents,

        [Parameter(
            ValueFromPipeline,
            HelpMessage = 'Specifies the name of the computer that this cmdlet gets events from the event logs.'
        )]
        [string[]]$ComputerName = $env:ComputerName,

        [Parameter(HelpMessage = 'This parameter limits the number of jobs running at one time. As jobs are started, they are queued and wait until a thread is available in the thread pool to run the job.')]
        [ValidateScript({ $_ -gt 0 })]
        [int]$ThrottleLimit = 5
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        $JobList = [System.Collections.Generic.list[object]]::New()
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting eventlog entries from $LogName"

        foreach ($computer in $ComputerName) {
            $job = {
                Param($LogName, $MaxEvents, $ComputerName)
                #match verbose preference
                $VerbosePreference = $using:VerbosePreference

                #remove MaxEvents if there is no value passed
                if ($PSBoundParameters['MaxEvents'] -le 1) {
                    [void]$PSBoundParameters.Remove('MaxEvents')
                }
                Try {
                    Write-Verbose "[$((Get-Date).TimeOfDay) THREAD ] Querying $($($PSBoundParameters)['LogName']) on $($PSBoundParameters['ComputerName'].ToUpper())"
                    $logs = Get-WinEvent @PSBoundParameters -ErrorAction Stop | Group-Object ProviderName
                    $LogCount = ($logs | Measure-Object -Property Count -Sum).sum
                    Write-Verbose "[$((Get-Date).TimeOfDay) THREAD ] Retrieved $($logs.count) event sources from $Logcount records."
                    Write-Verbose "[$((Get-Date).TimeOfDay) THREAD ] Detected log $($logs[0].group[0].LogName)"
                    $logs.foreach({
                            if ( $_.group[0].LogName -eq 'Security') {
                                $AS = (($_.group).where({ $_.Keywords.DisplayName[0] -match 'Success' }).count)
                                $AF = (($_.group).where({ $_.Keywords.DisplayName[0] -match 'Failure' }).count)
                            }
                            else {
                                $AS = 0
                                $AF = 0
                            }

                            $report = [PSCustomObject]@{
                                PSTypename   = 'WinEventReport'
                                LogName      = $_.group[0].LogName
                                Source       = $_.Name
                                Total        = $_.Count
                                Information  = (($_.group).where({ $_.level -eq 4 }).count)
                                Warning      = (($_.group).where({ $_.level -eq 3 }).count)
                                Error        = (($_.group).where({ $_.level -eq 2 }).count)
                                AuditSuccess = $AS
                                AuditFailure = $AF
                                ComputerName = $PSBoundParameters['ComputerName'].ToUpper()
                            }
                            $report
                        })
                } #Try
                Catch {
                    throw "Failed to query $($PSBoundParameters['ComputerName'].ToUpper()).$($_.Exception.Message)"
                }
                Write-Verbose "[$((Get-Date).TimeOfDay) THREAD ] Finished processing $($PSBoundParameters['ComputerName'].ToUpper())"
            }

            $JobList.Add((Start-ThreadJob -Name $computer -ScriptBlock $job -ArgumentList $LogName, $MaxEvents, $computer -ThrottleLimit $ThrottleLimit))
        } #foreach computer
    } #process

    End {
        $count = $JobList.count
        do {
            Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Waiting for jobs to finish: $( $JobList.Where({$_.state -notmatch 'completed|failed'}).Name -join ',')"
            [string[]]$waiting = $JobList.Where({ $_.state -notmatch 'completed|failed' }).Name
            if ($waiting.count -gt 0) {
                #write-progress doesn't display right at 0%
                if ($waiting.count -eq $count) {
                    [int]$pc = 5
                }
                else {
                    [int]$pc = (100 - ($waiting.count / $count) * 100)
                }
                Write-Progress -Activity "Waiting for $($JobList.count) jobs to complete." -Status "$($waiting -join ',') $pc%" -PercentComplete $pc
            }
            $JobList.Where({ $_.state -match 'completed|failed' }) | ForEach-Object { Receive-Job $_.id -Keep ; [void]$JobList.remove($_) }
            #wait 1 second before checking again
            Start-Sleep -Milliseconds 1000
        } while ($JobList.count -gt 0)

        if ($JobList.state -contains 'failed') {
            $JobList.Where({ $_.state -match 'failed' }) | ForEach-Object {
                $msg = '[{0}] Failed. {1}' -f $_.Name.toUpper(), ((Get-Job -Id $_.id).ChildJobs.JobStateInfo.Reason.Message)
                Write-Warning $msg
            }
        }
        #ThreadJob remain with results so you can retrieve data again.
        #You can manually remove the jobs.
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-WinEventReport