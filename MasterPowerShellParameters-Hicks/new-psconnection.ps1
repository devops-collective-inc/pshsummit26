#requires -version 5.1

#create a remote session and run a remote profile script
Function New-PSConnection {
    [cmdletbinding(DefaultParameterSetName = "wsman")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "The name of a Windows computer to connect to using legacy PowerShell remoting.",
            ParameterSetName = "wsman"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Computername,

        [Parameter(
            HelpMessage = "A Windows credential for legacy PowerShell remoting",
            ParameterSetName = "wsman"
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "The path to the remote profile script on the local computer.")]
        [ValidateScript({ Test-Path $_ })]
        [string]$RemoteProfile = "c:\scripts\RemoteProfile.ps1"
    )
    DynamicParam {
        # Add ssh-related parameters if running PowerShell 7
        If ($PSEdition -eq 'Core') {
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

            # Defining parameter attributes
            $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.ParameterSetName = 'ssh'
            $attributes.Mandatory = $True
            $attributes.HelpMessage = 'Enter the name of an ssh host running PowerShell 7.'

            # Adding ValidateNotNullOrEmpty parameter validation
            $v = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
            $AttributeCollection.Add($v)
            $attributeCollection.Add($attributes)

            # Defining the runtime parameter
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter('Hostname', [String], $attributeCollection)
            $paramDictionary.Add('Hostname', $dynParam1)

            #repeat the process for the Username parameter
            $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.ParameterSetName = 'ssh'
            $attributes.HelpMessage = 'Enter the user name for the ssh connection using PowerShell 7.'

            # Adding ValidateNotNullOrEmpty parameter validation
            $v = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
            $AttributeCollection.Add($v)
            $attributeCollection.Add($attributes)

            # Defining the runtime parameter
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter('Username', [String], $attributeCollection)
            $paramDictionary.Add('Username', $dynParam1)

            return $paramDictionary
        } # end if
    } #end DynamicParam
    Begin {
        <#
        Because I will eventually splat PSBoundParameters
        to New-PSSession, I need to remove parameters that New-PSSession
        won't recognize like RemoteProfile
        #>
        if ($PSBoundParameters.ContainsKey("RemoteProfile")) {
            $PSBoundParameters.Remove("RemoteProfile")
        }
        #add default parameters
        $PSBoundParameters.Add("ErrorAction","Stop")
    } #begin
    Process {
        Try {
            $newSession = New-PSSession @PSBoundParameters
            #run the remote profile script in the remote session
            Invoke-Command -FilePath $RemoteProfile -Session $newSession -HideComputerName -ErrorAction Stop |
            Select-Object -ExcludeProperty RunspaceID
            #enter the PSSession
            Enter-PSSession $newSession
            #manually remove the PSSession when finished
        }
        Catch {
            Throw $_
        }
    } #process
    End {
        #not used
    } #end
}