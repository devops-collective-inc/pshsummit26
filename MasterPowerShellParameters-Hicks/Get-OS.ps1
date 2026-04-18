#requires -version 7
#requires -module CimCmdlets

function Get-OS {
    [CmdletBinding(DefaultParameterSetName = 'computername')]
    param(
        [Parameter(
            Position = 0,
            ParameterSetName = 'CimSession',
            Mandatory,
            ValueFromPipeline,
            HelpMessage = 'Use an existing CIM session'
        )]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,

        [Parameter(
            Position = 0,
            ParameterSetName = 'computername',
            ValueFromPipeline,
            HelpMessage = 'Specify the name of a computer to query.'
        )]
        [Alias('CN', 'ServerName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(HelpMessage = 'Specifies the amount of time that the cmdlet waits for a response from the computer. By default, the value of this parameter is 0, which means that the cmdlet uses the default timeout value for the server.' )]
        [Alias('OT')]
        [uint32]$OperationTimeoutSec
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        #limit CIM properties for better performance
        $select = 'CSName', 'Caption', 'Version', 'BuildNumber', 'InstallDate', 'OSArchitecture'

        $PSBoundParameters.Add('Classname', 'Win32_OperatingSystem')
        $PSBoundParameters.Add('Property', $select)
        $PSBoundParameters.Add('ErrorAction', 'Stop')

    } #begin

    process {
         Write-Verbose "Process: $($PSBoundParameters | Out-String)"
        #initialize an array to hold results
        $data = @()

        Write-Verbose "Process: Using parameter set $($PSCmdlet.ParameterSetName)"
        if ($PSCmdlet.ParameterSetName -eq 'computername') {
            foreach ($name in $ComputerName) {
            #process multiple computers individually
            if ($PSBoundParameters.ContainsKey('Computername')) {
                $PSBoundParameters["computername"] = $Name
            }

                Write-Verbose "Query $($name.ToUpper())"
                try {
                    #Write-Verbose "Process actually using $($PSBoundParameters | Out-String)"
                    $data += Get-CimInstance @PSBoundParameters
                }
                catch {
                    Write-Warning "Failed to get operating system information from $($name.ToUpper()). $($_.Exception.Message)"
                }
            }
        }
        else {
            try {
                Write-Verbose "Processing CIMSessions"
                $data += Get-CimInstance @PSBoundParameters
            }
            catch {
                Write-Warning "Failed to get operating system information from $($CimSession.Computername.ToUpper()). $($_.Exception.Message)"
            }
        }

        if ($data) {
            #create custom object output
            foreach ($item in $data) {
                #there might be results from multiple computers
                [PSCustomObject]@{
                    Name         = $item.Caption
                    Version      = $item.Version
                    BuildNumber  = $item.BuildNumber
                    Installed    = $item.InstallDate
                    Architecture = $item.OSArchitecture
                    Computername = $item.CSName
                }
            }
        }

    } #process

    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    } #end

} #end function Get-OS