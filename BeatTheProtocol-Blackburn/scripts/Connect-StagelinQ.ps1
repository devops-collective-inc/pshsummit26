# Test: StateMap with fixed value parsing, longer timeout, keepalive handling
# Same as Test-StateMap2 but with the value parsing fixed and 60s timeout

function Read-PrefixedString {
    param([byte[]]$Data, [int]$Offset)
    $lengthBytes = $Data[$Offset..($Offset + 3)]
    [Array]::Reverse($lengthBytes)
    $length = [System.BitConverter]::ToUInt32($lengthBytes, 0)
    $text = [System.Text.Encoding]::BigEndianUnicode.GetString($Data, $Offset + 4, $length)
    [PSCustomObject]@{ Text = $text; NewOffset = $Offset + 4 + $length }
}

function Read-DiscoveryFrame {
    param([byte[]]$Data)
    $magic = [System.Text.Encoding]::ASCII.GetString($Data, 0, 4)
    if ($magic -ne 'airD') { throw "Not a StagelinQ frame" }
    $token = $Data[4..19]
    $offset = 20
    $dn = Read-PrefixedString -Data $Data -Offset $offset; $offset = $dn.NewOffset
    $ct = Read-PrefixedString -Data $Data -Offset $offset; $offset = $ct.NewOffset
    $sn = Read-PrefixedString -Data $Data -Offset $offset; $offset = $sn.NewOffset
    $sv = Read-PrefixedString -Data $Data -Offset $offset; $offset = $sv.NewOffset
    $port = ([int]$Data[$offset] -shl 8) + $Data[$offset + 1]
    [PSCustomObject]@{
        DeviceName = $dn.Text; ConnectionType = $ct.Text; SoftwareName = $sn.Text
        SoftwareVersion = $sv.Text; ServicePort = $port; Token = [byte[]]$token; SourceAddress = $null
    }
}

function Write-BigEndianUInt32 {
    param([System.IO.BinaryWriter]$Writer, [uint32]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    [Array]::Reverse($bytes)
    $Writer.Write($bytes)
}

function Write-BigEndianUInt16 {
    param([System.IO.BinaryWriter]$Writer, [uint16]$Value)
    $Writer.Write([byte](($Value -shr 8) -band 0xFF))
    $Writer.Write([byte]($Value -band 0xFF))
}

function Write-NetworkStringUTF16 {
    param([System.IO.BinaryWriter]$Writer, [string]$Text)
    $strBytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes($Text)
    Write-BigEndianUInt32 -Writer $Writer -Value ([uint32]$strBytes.Length)
    $Writer.Write($strBytes)
}

function Build-DiscoveryFrame {
    param([byte[]]$Token, [string]$Source, [string]$Action, [string]$SoftwareName, [string]$Version, [int]$Port)
    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)
    $bw.Write([System.Text.Encoding]::ASCII.GetBytes('airD'))
    $bw.Write($Token)
    foreach ($str in @($Source, $Action, $SoftwareName, $Version)) {
        Write-NetworkStringUTF16 -Writer $bw -Text $str
    }
    $bw.Write([byte](($Port -shr 8) -band 0xFF))
    $bw.Write([byte]($Port -band 0xFF))
    $bw.Flush()
    [byte[]]$result = $ms.ToArray()
    $bw.Close(); $ms.Close()
    $result
}

function Build-StateMapSubscription {
    param([string[]]$Paths)
    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)
    foreach ($path in $Paths) {
        $pathBytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes($path)
        $payloadLength = 8 + 4 + $pathBytes.Length + 4
        Write-BigEndianUInt32 -Writer $bw -Value ([uint32]$payloadLength)
        $bw.Write([byte[]]@(0x73, 0x6D, 0x61, 0x61, 0x00, 0x00, 0x07, 0xD2))
        Write-BigEndianUInt32 -Writer $bw -Value ([uint32]$pathBytes.Length)
        $bw.Write($pathBytes)
        $bw.Write([byte[]]@(0x00, 0x00, 0x00, 0x00))
    }
    $bw.Flush()
    [byte[]]$result = $ms.ToArray()
    $bw.Close(); $ms.Close()
    $result
}

function Parse-StateValue {
    param([byte[]]$ValueBytes)
    # Format: 4-byte length (big-endian) + 1 byte (0x00) + JSON (UTF-8)
    if ($ValueBytes.Length -lt 5) { return "(raw: $([BitConverter]::ToString($ValueBytes) -replace '-', ' '))" }
    $jsonStart = 5
    $jsonBytes = $ValueBytes[$jsonStart..($ValueBytes.Length - 1)]
    [System.Text.Encoding]::UTF8.GetString($jsonBytes).Trim("`0")
}

$soundSwitchToken = [byte[]]@(0x52, 0xFD, 0xFC, 0x07, 0x21, 0x82, 0x65, 0x4F, 0x16, 0x3F, 0x5F, 0x0F, 0x9A, 0x62, 0x1D, 0x72)

# === PHASE 1: Announce and discover ===
Write-Host "=== Phase 1: Announce and Discover ==="
$announceFrame = Build-DiscoveryFrame -Token $soundSwitchToken -Source 'powershell' -Action 'DISCOVERER_HOWDY_' -SoftwareName 'nowplaying' -Version '1.0.0' -Port 0

$announceSocket = [System.Net.Sockets.UdpClient]::new()
$announceSocket.EnableBroadcast = $true
$broadcastEp = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Broadcast, 51337)

for ($i = 0; $i -lt 5; $i++) {
    $announceSocket.Send($announceFrame, $announceFrame.Length, $broadcastEp) | Out-Null
    Start-Sleep -Milliseconds 500
}

$bgRunspace = [runspacefactory]::CreateRunspace()
$bgRunspace.Open()
$bgRunspace.SessionStateProxy.SetVariable('announceSocket', $announceSocket)
$bgRunspace.SessionStateProxy.SetVariable('announceFrame', $announceFrame)
$bgRunspace.SessionStateProxy.SetVariable('broadcastEp', $broadcastEp)
$bgAnnounce = [powershell]::Create().AddScript({
    while ($true) {
        try { $announceSocket.Send($announceFrame, $announceFrame.Length, $broadcastEp) | Out-Null } catch {}
        Start-Sleep -Milliseconds 1000
    }
})
$bgAnnounce.Runspace = $bgRunspace
$bgAnnounce.BeginInvoke() | Out-Null

$listenSocket = [System.Net.Sockets.UdpClient]::new(51337)
$listenSocket.Client.ReceiveTimeout = 5000
$endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
$deviceFrame = $null
try {
    while ($null -eq $deviceFrame) {
        $bytes = $listenSocket.Receive([ref]$endpoint)
        $parsed = Read-DiscoveryFrame -Data $bytes
        $parsed.SourceAddress = $endpoint.Address.ToString()
        if ($parsed.SoftwareName -eq 'JP11S') { $deviceFrame = $parsed }
    }
} catch { Write-Host "Discovery timeout."; exit 1 }
$listenSocket.Close()
$ip = $deviceFrame.SourceAddress
Write-Host "Found: $($deviceFrame.DeviceName) at ${ip}:$($deviceFrame.ServicePort)"

# === PHASE 2: Directory server ===
Write-Host "`n=== Phase 2: Directory Server ==="
$dirTcp = [System.Net.Sockets.TcpClient]::new()
$dirTcp.Connect($ip, $deviceFrame.ServicePort)
$dirStream = $dirTcp.GetStream()
$dirStream.ReadTimeout = 15000

$buffer = [byte[]]::new(4096)
$stateMapPort = 0
$serviceRequestReceived = $false

while ($true) {
    $bytesRead = $dirStream.Read($buffer, 0, $buffer.Length)
    if ($bytesRead -eq 0) { break }
    $pos = 0
    while ($pos -lt $bytesRead) {
        if ($pos + 4 -gt $bytesRead) { break }
        $msgId = ([int]$buffer[$pos] -shl 24) + ([int]$buffer[$pos+1] -shl 16) + ([int]$buffer[$pos+2] -shl 8) + $buffer[$pos+3]
        $pos += 4
        switch ($msgId) {
            0x00000001 { $pos += 40 }
            0x00000000 {
                $pos += 16
                $result = Read-PrefixedString -Data $buffer -Offset $pos
                $pos = $result.NewOffset
                $svcPort = ([int]$buffer[$pos] -shl 8) + $buffer[$pos+1]
                $pos += 2
                Write-Host "  $($result.Text) => port $svcPort"
                if ($result.Text -eq 'StateMap') { $stateMapPort = $svcPort }
            }
            0x00000002 { $pos += 16; $serviceRequestReceived = $true }
            default { $pos = $bytesRead }
        }
    }
    if ($serviceRequestReceived) {
        $request = [byte[]]::new(20)
        $request[3] = 0x02
        [Array]::Copy($soundSwitchToken, 0, $request, 4, 16)
        $dirStream.Write($request, 0, $request.Length)
        $dirStream.Flush()
        $serviceRequestReceived = $false
    }
    if ($stateMapPort -gt 0) { break }
}
Write-Host "StateMap on port $stateMapPort"

# Keep directory server alive in background
$dirRunspace = [runspacefactory]::CreateRunspace()
$dirRunspace.Open()
$dirRunspace.SessionStateProxy.SetVariable('dirStream', $dirStream)
$bgDir = [powershell]::Create().AddScript({
    $buf = [byte[]]::new(4096)
    try {
        while ($true) {
            $n = $dirStream.Read($buf, 0, $buf.Length)
            if ($n -eq 0) { break }
        }
    } catch {}
})
$bgDir.Runspace = $dirRunspace
$bgDir.BeginInvoke() | Out-Null

# === PHASE 3: StateMap ===
Write-Host "`n=== Phase 3: StateMap ==="
Start-Sleep -Milliseconds 500

$smTcp = [System.Net.Sockets.TcpClient]::new()
$smTcp.Connect($ip, $stateMapPort)
$smStream = $smTcp.GetStream()
$smStream.ReadTimeout = 60000  # 60 second timeout

# Connection frame
$ms = [System.IO.MemoryStream]::new()
$bw = [System.IO.BinaryWriter]::new($ms)
Write-BigEndianUInt32 -Writer $bw -Value 0x00000000
$bw.Write($soundSwitchToken)
Write-NetworkStringUTF16 -Writer $bw -Text 'StateMap'
Write-BigEndianUInt16 -Writer $bw -Value 0
$bw.Flush()
$connectMsg = [byte[]]$ms.ToArray()
$bw.Close(); $ms.Close()
$smStream.Write($connectMsg, 0, $connectMsg.Length)
$smStream.Flush()
Start-Sleep -Milliseconds 500

# Subscribe
$paths = @(
    '/Engine/Deck1/Track/SongName',
    '/Engine/Deck1/Track/ArtistName',
    '/Engine/Deck1/CurrentBPM',
    '/Engine/Deck1/PlayState',
    '/Engine/Mixer/CrossfaderPosition'
)
$subMsg = Build-StateMapSubscription -Paths $paths
$smStream.Write($subMsg, 0, $subMsg.Length)
$smStream.Flush()

Write-Host "Subscribed. Waiting for updates (press play/pause, move crossfader, load a track)..."
Write-Host "Ctrl+C to stop.`n"

$smBuffer = [byte[]]::new(8192)

try {
    while ($true) {
        $bytesRead = $smStream.Read($smBuffer, 0, $smBuffer.Length)
        if ($bytesRead -eq 0) { Write-Host "Connection closed."; break }

        $pos = 0
        while ($pos -lt $bytesRead) {
            if ($pos + 4 -gt $bytesRead) { break }

            $lenBytes = $smBuffer[$pos..($pos+3)]
            [Array]::Reverse($lenBytes)
            $msgLen = [BitConverter]::ToUInt32($lenBytes, 0)
            $pos += 4

            if ($pos + $msgLen -gt $bytesRead) {
                Write-Host "[Incomplete: need $msgLen bytes]"
                $pos = $bytesRead; break
            }

            $msgEnd = $pos + $msgLen

            # Magic (4) + type (4)
            $magic = [System.Text.Encoding]::ASCII.GetString($smBuffer, $pos, 4)
            $smMsgType = ([int]$smBuffer[$pos+4] -shl 24) + ([int]$smBuffer[$pos+5] -shl 16) + ([int]$smBuffer[$pos+6] -shl 8) + $smBuffer[$pos+7]
            $pos += 8

            if ($magic -eq 'smaa') {
                $pathResult = Read-PrefixedString -Data $smBuffer -Offset $pos
                $pos = $pathResult.NewOffset

                $valueLen = $msgEnd - $pos
                if ($valueLen -gt 0) {
                    $valueBytes = $smBuffer[$pos..($pos + $valueLen - 1)]
                    $json = Parse-StateValue -ValueBytes $valueBytes

                    # Pretty print based on path
                    $shortPath = $pathResult.Text -replace '^/Engine/', ''
                    $timestamp = Get-Date -Format 'HH:mm:ss'
                    Write-Host "[$timestamp] $shortPath = $json"
                }
                $pos = $msgEnd
            } else {
                Write-Host "[msg magic=$magic type=0x$($smMsgType.ToString('X8')) len=$msgLen]"
                $pos = $msgEnd
            }
        }
    }
} catch [System.IO.IOException] {
    Write-Host "`nTimed out (60s with no data)."
} catch {
    Write-Host "`nError: $_"
}

$smTcp.Close()
$dirTcp.Close()
$bgDir.Stop(); $dirRunspace.Close()
$bgAnnounce.Stop(); $bgRunspace.Close()
$announceSocket.Close()
Write-Host "Done."
