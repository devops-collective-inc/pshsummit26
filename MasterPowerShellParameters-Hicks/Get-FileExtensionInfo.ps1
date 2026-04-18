#requires -version 7
using namespace System.Collections.generic

function Get-FileExtensionInfo {
    [cmdletbinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the root directory path to search'
        )]
        [ValidateScript({ Test-Path $_ }, ErrorMessage = 'Cannot find or validate the path {0}')]
        [string]$Path = '.',

        [Parameter(HelpMessage = 'Recurse through all folders.')]
        [switch]$Recurse,

        [Parameter(HelpMessage = 'Add the corresponding collection of files')]
        [alias("if")]
        [Switch]$IncludeFiles,

        [Parameter(HelpMessage = 'Include files in hidden folders')]
        [switch]$Hidden
    )

    begin {
        #set a version for this stand-alone function
        $ver = '1.5.0'
        #capture the current date and time for the audit date
        $report = Get-Date

        #determine the platform. This will return a value like Linux, MacOS, or Windows
        $platform = (Get-Variable IsWindows, IsMacOS, IsLinux | where { $_.value }).Name -replace 'is', ''
    } #begin

    process {
        $global:mi = $MyInvocation
        #initialize a list for the files
        $fileList = [list[system.io.fileInfo]]::new()
        #initialize a list to hold the results
        $list = [list[object]]::new()
        <#
            This code is for demonstration purposes. My code is not the only,
            or even the best way to get the desired results
        #>
        #need to reset PSBoundParameters for each pipelined folder
        $splat = ($PSBoundParameters -as [hashtable]).Clone()

        #remove IncludeFiles from PSBoundParameters
        if ($splat.ContainsKey('IncludeFiles')) {
            [void]($splat.Remove('IncludeFiles'))
        }

        #add an item to PSBoundParameters
        $splat.Add('File', $True)

        if ($splat.ContainsKey('Hidden')) {
            #get hidden files first
            #this won't find files in hidden folders
            Get-ChildItem @Splat | ForEach-Object { $fileList.Add($_) }

            [void]($splat.Remove('Hidden'))
        }

        #make a second pass to get all files
        Get-ChildItem @splat| ForEach-Object { $fileList.Add($_) }

        #measure total size
        $TotalSum = $fileList | Measure-Object -Property length -Sum
        $group = $fileList | Group-Object -Property extension

        #Group and measure
        foreach ($item in $group) {
            $measure = $item.Group | Measure-Object -Property length -Minimum -Maximum -Average -Sum

            #create a custom object
            $out = [PSCustomObject]@{
                Path             = $Path
                Extension        = $item.Name.Replace('.', '')
                Count            = $item.Count
                PercentTotal     = [math]::Round(($item.Count / $fileList.Count), 4)  #<-- cast as double for sorting
                TotalSize        = $measure.Sum -as [int64] #<-- don't format numbers here to KB or MB
                TotalSizePercent = [math]::Round(($measure.Sum / $TotalSum.Sum), 4)
                SmallestSize     = $measure.Minimum -as [int]
                LargestSize      = $measure.Maximum -as [int]
                AverageSize      = $measure.Average
                Computername     = [System.Environment]::MachineName  #<-- extra information
                Platform         = $platform #<-- extra information
                ReportDate       = $report #<-- extra information
                Files            = $IncludeFiles ? $item.group : $null  #<-- extra information
                IsLargest        = $False  #<-- extra information
            }
            $list.Add($out)
        }
    } #process

    end {
        #mark the extension with the largest total size
        if ($list) {
            ($list | Sort-Object -Property TotalSize, Count)[-1].IsLargest = $True
            #write the results to the pipeline
            $list
        }
    } #end
} #close Get-FileExtensionInfo