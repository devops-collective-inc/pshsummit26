function Read-DiscoveryFrame {
    <#
    .SYNOPSIS
    Parses a StagelinQ discovery frame from a byte array.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [byte[]]$Data
    )

    process {
        $magic = [System.Text.Encoding]::ASCII.GetString($Data, 0, 4)
        if ($magic -ne 'airD') {
            throw "Not a StagelinQ discovery frame (magic: $magic)"
        }

        $token = [byte[]]$Data[4..19]
        $offset = 20

        $deviceName = Read-PrefixedString -Data $Data -Offset $offset
        $offset = $deviceName.NewOffset

        $connectionType = Read-PrefixedString -Data $Data -Offset $offset
        $offset = $connectionType.NewOffset

        $softwareName = Read-PrefixedString -Data $Data -Offset $offset
        $offset = $softwareName.NewOffset

        $softwareVersion = Read-PrefixedString -Data $Data -Offset $offset
        $offset = $softwareVersion.NewOffset

        $port = ([int]$Data[$offset] -shl 8) + $Data[$offset + 1]

        [PSCustomObject]@{
            PSTypeName      = 'StagelinQ.DiscoveryFrame'
            DeviceName      = $deviceName.Text
            ConnectionType  = $connectionType.Text
            SoftwareName    = $softwareName.Text
            SoftwareVersion = $softwareVersion.Text
            ServicePort     = $port
            Token           = $token
            TokenHex        = [BitConverter]::ToString($token) -replace '-', ''
            SourceAddress   = $null
            FrameLength     = $Data.Length
        }
    }
}
