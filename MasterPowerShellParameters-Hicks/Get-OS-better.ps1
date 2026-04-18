#requires -version 7
#requires -module CimCmdlets

function Get-OS {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Specify the name of a computer to query.'
        )]
        [ValidateNotNullOrEmpty()]
        [alias('CN', 'ServerName')]
        [string]$ComputerName = $env:Computername,

        [Parameter(HelpMessage = 'Specify an alternate credential')]
        [alias('RunAs')]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,

        [UInt32]$Timeout = 0
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        #limit the properties returned to improve performance
        $select = 'CSName', 'Caption', 'Version', 'BuildNumber', 'InstallDate', 'OSArchitecture'

        $cimSplat = @{
            Classname           = 'Win32_OperatingSystem'
            Property            = $select
            ErrorAction         = 'Stop'
            OperationTimeoutSec = $Timeout
            CimSession          = $null
        }
    } #begin

    process {
        try {
            #create a temp CimSession if using a credential
            if ($Credential) {
                Write-Verbose "Creating temporary CIMSession to $Computername"
                $tmpCS = New-CimSession -ComputerName $Computername -Credential $Credential -ErrorAction Stop
                $tmpFlag = $True
            }
            else {
                $tmpCS = $ComputerName
                $tmpFlag = $False
            }

            $cimSplat['CimSession'] = $tmpCS

            $data = Get-CimInstance @cimSplat
            #create custom object output
            [PSCustomObject]@{
                Name         = $data.Caption
                Version      = $data.Version
                BuildNumber  = $data.BuildNumber
                Installed    = $data.InstallDate
                Architecture = $data.OSArchitecture
                Computername = $data.CSName
            }
        }
        catch {
            Write-Warning $_.Exception.Message
        }
        finally {
            if ($tmpFlag) {
                $tmpCS | Remove-CimSession
            }
        }
    } #process

    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"

    } #end

} #end function Get-OS