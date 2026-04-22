#region LoggingParams
[string]$LogPath = "C:\_AAWorkingDir\AALogs" #Path to store the Lofgile, only local or Hybrid
[string]$LogfileName = "RB_001_002_006_AssetExportReporting" #FileName of the Logfile, only local or Hybrid
[int]$DeleteAfterDays = 10 #Time Period in Days when older Files will be deleted, only local or Hybrid
$environment = "AAnoHybrid" #AAHybrid, AAnoHybrid, local
$LogLevel = "INFO" #DEBUG, INFO, WARNING, ERROR
$LogLocation = "Azure" #Local, Hybrid, Azure

#endregion LoggingParams




#region Functions
function Write-AwesomeLog {
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        [string]$Text
    )


    if ($LogLevel -eq "DEBUG" -and ($Type -eq "DEBUG" -or $Type -eq "INFO" -or $Type -eq "WARNING" -or $Type -eq "ERROR")) {
        $Logging = $true
    }
    elseif ($LogLevel -eq "INFO" -and ($Type -eq "INFO" -or $Type -eq "WARNING" -or $Type -eq "ERROR")) {
        $Logging = $true
    }
    elseif ($LogLevel -eq "WARNING" -and ($Type -eq "WARNING" -or $Type -eq "ERROR")) {
        $Logging = $true
    }
    elseif ($LogLevel -eq "ERROR" -and $Type -eq "ERROR") {
        $Logging = $true
    }
    else {
        $Logging = $false
    }

    if ($Logging) {

        #Decide Platform
        if (($environment -eq "AAHybrid" -or $environment -eq "local") -and ($LogLocation -eq "Local" -or $LogLocation -eq "Hybrid")) {
            # Set logging path
            $LogPath = "$LogPath\$($LogfileName.Split("_")[1])\$($LogfileName.Split("_")[2])\$($LogfileName.Split("_")[3])"
            if (!(Test-Path -Path $logPath)) {
                try {
                    $null = New-Item -Path $logPath -ItemType Directory
                    Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
                }
                catch {
                    Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
                }
            }
            else {
                Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
            }
            [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyyMMdd'), $LogfileName
            $logEntry = '{0}: <{1}> {2}' -f $(Get-Date -Format yyyyMMdd_HHmmss), $Type, $Text
            Add-Content -Path $logFile -Value $logEntry
        }
        if (($environment -eq "AAHybrid" -or $environment -eq "AAnoHybrid") -and ($LogLocation -eq "Hybrid" -or $LogLocation -eq "Azure")) {
            $logEntry = '{0}: <{1}> {2}' -f $(Get-Date -Format yyyyMMdd_HHmmss), $Type, $Text

            switch ($Type) {
                INFO { Write-Output $logEntry }
                WARNING { Write-Warning $logEntry }
                ERROR { Write-Error $logEntry }
                DEBUG { Write-Output $logEntry }
                Default { Write-Output $logEntry }
            }
        }
    }
}

#endregion Functions



#region StartScript
Write-AwesomeLog INFO "Start Script"



Write-AwesomeLog ERROR "This is an Error"


Write-AwesomeLog WARNING "this is a Warning"

Write-AwesomeLog INFO "Do some awesome stuff"







#endregion StartScript



if ($LogLocation -eq "Local" -or $LogLocation -eq "Hybrid") {
    Write-AwesomeLog DEBUG "Delete Logfiles older than $DeleteAfterDays Days"
    $LogPath = "$LogPath\$($LogfileName.Split("_")[1])\$($LogfileName.Split("_")[2])\$($LogfileName.Split("_")[3])"
    $LogFiles = Get-ChildItem -Path $LogPath -Filter "*$LogfileName*" -File
    $LogFiles | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DeleteAfterDays) } | Remove-Item -Force
}



Write-AwesomeLog DEBUG "END Script"
