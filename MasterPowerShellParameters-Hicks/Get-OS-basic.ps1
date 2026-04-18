#requires -version 7
#requires -module CimCmdlets

function Get-OS {
    [CmdletBinding()]
    param(
        $ComputerName = $env:Computername,
        $Credential,
        $Timeout = 0
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
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

            Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec $TimeOut -CimSession $tmpCS |
            Select-Object @{Name = 'Computername'; Expression = { $_.CSName } },
            @{Name = 'Name'; Expression = { $_.Caption } },
            Version, BuildNumber, InstallDate, OSArchitecture
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