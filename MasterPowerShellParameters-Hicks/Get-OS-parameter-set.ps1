function Get-OS {
    [CmdletBinding(DefaultParameterSetName = 'computer')]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'computer',
            HelpMessage = 'Specify the name of a computer to query.'
        )]
        [ValidateNotNullOrEmpty()]
        [alias('CN', 'ServerName')]
        [string]$ComputerName = $env:Computername,

        [Parameter(
            ParameterSetName = 'computer',
            HelpMessage = 'Specify an alternate credential'
        )]
        [alias('RunAs')]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify an existing CIMSession',
            ParameterSetName = 'session'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_.TestConnection() }, ErrorMessage = "The specified CIMSession isn't open or the computer isn't reachable.")]
        [CimSession]$CimSession,

        [Parameter(HelpMessage = "Specifies the amount of time in seconds that the command waits for a response from the computer. By default, the value of this parameter is 0, which means that the command uses the default timeout value for the remote computer.")]
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
        if ($PSCmdlet.ParameterSetName -eq 'Computer') {
            try {
                #create a temp CimSession if using a credential
                Write-Verbose "Creating temporary CIMSession to $Computername"
                if ($Credential) {
                    $CimSession = New-CimSession -ComputerName $Computername -Credential $Credential -ErrorAction Stop
                }
                else {
                    $CimSession = New-CimSession -ComputerName $Computername -ErrorAction Stop
                }
                $tmpFlag = $True
            } #Try
            catch {
                Write-Warning $_.Exception.Message
            } #Catch
        } #if computer
        else {
            Write-Verbose "Using an existing CIMSession to $($CimSession.Computername)"
        }
        if ($CimSession.ComputerName) {
            $cimSplat['CimSession'] = $CimSession

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


            if ($tmpFlag) {
                Write-Verbose 'Removing temporary CIMSession'
                $CimSession | Remove-CimSession
            }
        } #if valid CimSession

    } #process

    end {
        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    } #end

} #end function Get-OS