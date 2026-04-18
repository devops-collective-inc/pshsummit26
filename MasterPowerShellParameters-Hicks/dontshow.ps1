function Get-OSPeek {
    [cmdletbinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('CN')]
        [string]$Computername = $env:computername,

        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,

        [Parameter(DontShow)]
        [ValidateSet("Csv","Json","Xml")]
        [ObsoleteAttribute("This parameter is deprecated and will be removed in the next release. Pipe output of this command to the appropriate PowerShell cmdlet.")]
        [string]$As
    )

    begin {
        $get = { Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption, InstallDate, CSName }
        $PSBoundParameters.Add('Scriptblock', $Get)
        $PSBoundParameters.Add('ErrorAction', 'Stop')
        If ($PSBoundParameters.ContainsKey("As")) {
            [void]$PSBoundParameters.Remove("As")
        }
    }

    process {
        try {
            $r = Invoke-Command @PSBoundParameters
            $out =[PSCustomObject]@{
                PSTypename   = 'OSInfo'
                Name         = $r.Caption
                Installed    = $r.InstallDate
                Computername = $r.CSName
            }
        }
        catch {
            $_
            Break
        }
        if ($As) {
            #this code is deprecated
            Switch ($As) {
                "Csv" { $out | ConvertTo-Csv}
                "Json" { $out | ConvertTo-Json}
                "Xml" { $out | ConvertTo-Xml -As Stream}
            }
        }
        else {
            $out
        }
    }
    end {
        #not used
    }
}