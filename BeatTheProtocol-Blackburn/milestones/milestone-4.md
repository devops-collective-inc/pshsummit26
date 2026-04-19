# Milestone 4: Subscribe to StateMap

- **Type:** Live hardware (requires the Prime Go+ on the challenge network)
- **Difficulty:** Advanced
- **Tools needed:** [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell), [Wireshark](https://www.wireshark.org) (free)

## Objective

Connect to the Prime Go+'s StateMap service and receive live DJ data — track names, BPM, play state, and fader positions — in real time. This is the payoff: your PowerShell script will display what the DJ is doing as it happens.

## Before You Start

You should have completed [Milestone 3](milestone-3.md) and have a working script that announces, connects to the directory server, and retrieves the service list. You'll need the **StateMap port** from that service list.

Keep your directory server connection and UDP announcements running — the device needs both to stay active.

## Step 1: Find the StateMap magic

Open `captures/03-active-session.pcapng` in Wireshark. This capture shows a complete StateMap session with live interactions — play/pause, track loading, and crossfader movement.

This capture has two TCP connections — the first is the directory server handshake, the second is the StateMap session. Right-click on any TCP packet from the second connection and select **Follow** > **TCP Stream**. You'll see the raw bytes of the StateMap conversation.

Look for a repeating 4-byte pattern in the data sent by the device. Just like `airD` identifies discovery frames, StateMap messages have their own magic bytes.

<details>
<summary>What do you find?</summary>

The magic bytes are `smaa` (`0x73 0x6D 0x61 0x61`). You'll see them at the start of every StateMap message payload.

</details>

## Step 2: Connect to StateMap

Connect to the StateMap port from your service list. The connection frame follows the same format as the Service Announcements you parsed in Milestone 3 — but now you're building it instead of reading it:

- Message type: `0x00000000` (4 bytes, big-endian)
- Your token (16 bytes)
- Service name: `"StateMap"` (length-prefixed UTF-16BE)
- Port: `0` (2 bytes, big-endian)

<details>
<summary>Hint</summary>

```powershell
$smTcp = [System.Net.Sockets.TcpClient]::new()
$smTcp.Connect($deviceIp, $stateMapPort)  # from milestone 3's service list
$smStream = $smTcp.GetStream()
$smStream.ReadTimeout = 30000

$ms = [System.IO.MemoryStream]::new()
$bw = [System.IO.BinaryWriter]::new($ms)

# Message type 0x00000000
$typeBytes = [BitConverter]::GetBytes([uint32]0)
[Array]::Reverse($typeBytes)
$bw.Write($typeBytes)

# Token
$bw.Write($token)

# "StateMap" as length-prefixed UTF-16BE
$strBytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes('StateMap')
$lenBytes = [BitConverter]::GetBytes([uint32]$strBytes.Length)
[Array]::Reverse($lenBytes)
$bw.Write($lenBytes)
$bw.Write($strBytes)

# Port 0
$bw.Write([byte]0)
$bw.Write([byte]0)

$bw.Flush()
$connectMsg = [byte[]]$ms.ToArray()
$bw.Close(); $ms.Close()

$smStream.Write($connectMsg, 0, $connectMsg.Length)
$smStream.Flush()
```

</details>

## Step 3: Subscribe to state paths

To receive data, you need to tell the device which values you want. The Prime Go+ exposes hundreds of state paths like `/Engine/Deck1/Track/SongName` and `/Engine/Mixer/CrossfaderPosition`.

Each subscription message has this format:

- **Total length** (4 bytes, big-endian) — byte count of everything that follows
- **Magic** (8 bytes) — `smaa` followed by `0x000007D2`: `0x73 0x6D 0x61 0x61 0x00 0x00 0x07 0xD2`
- **Path length** (4 bytes, big-endian) — byte count of the UTF-16BE path
- **Path** (variable) — the state path in UTF-16BE
- **Delimiter** (4 bytes) — `0x00 0x00 0x00 0x00`

Here are some paths to try:

```text
/Engine/Deck1/Track/SongName
/Engine/Deck1/Track/ArtistName
/Engine/Deck1/CurrentBPM
/Engine/Deck1/PlayState
/Engine/Mixer/CrossfaderPosition
```

Build a subscription message for each path and send them.

<details>
<summary>Hint: subscription builder</summary>

```powershell
function Build-StateMapSubscription {
    param([string[]]$Paths)

    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)

    foreach ($path in $Paths) {
        $pathBytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes($path)

        # Total payload: 8 (magic) + 4 (path length) + pathBytes + 4 (delimiter)
        $payloadLength = 8 + 4 + $pathBytes.Length + 4
        $lenBytes = [BitConverter]::GetBytes([uint32]$payloadLength)
        [Array]::Reverse($lenBytes)
        $bw.Write($lenBytes)

        # Magic: smaa + 0x000007D2
        $bw.Write([byte[]]@(0x73, 0x6D, 0x61, 0x61, 0x00, 0x00, 0x07, 0xD2))

        # Path length + path
        $pathLenBytes = [BitConverter]::GetBytes([uint32]$pathBytes.Length)
        [Array]::Reverse($pathLenBytes)
        $bw.Write($pathLenBytes)
        $bw.Write($pathBytes)

        # Delimiter
        $bw.Write([byte[]]@(0x00, 0x00, 0x00, 0x00))
    }

    $bw.Flush()
    [byte[]]$result = $ms.ToArray()
    $bw.Close(); $ms.Close()
    $result
}
```

</details>

## Step 4: Receive and parse state data

The device responds with state values. Each message follows this format:

- **Total length** (4 bytes, big-endian)
- **Magic** (4 bytes) — `smaa`
- **Message type** (4 bytes, big-endian)
- **Path** — length-prefixed UTF-16BE string (same format as before)
- **Value** — 4-byte big-endian length + 1 null byte + UTF-8 JSON

The JSON values look like:

```json
{"string":"Play (Purple Disco Machine Remix)","type":8}
{"type":0,"value":124.86}
{"state":true,"type":1}
```

Parse the messages and display the path and value.

<details>
<summary>Hint: parsing state messages</summary>

```powershell
$smBuffer = [byte[]]::new(8192)
$bytesRead = $smStream.Read($smBuffer, 0, $smBuffer.Length)

$pos = 0
while ($pos -lt $bytesRead) {
    # Read total message length
    $lenBytes = $smBuffer[$pos..($pos + 3)]
    [Array]::Reverse($lenBytes)
    $msgLen = [BitConverter]::ToUInt32($lenBytes, 0)
    $pos += 4

    $msgEnd = $pos + $msgLen

    # Skip magic (4 bytes) + message type (4 bytes)
    $pos += 8

    # Read path
    $pathResult = Read-PrefixedString -Data $smBuffer -Offset $pos
    $pos = $pathResult.NewOffset

    # Read value: skip 4-byte length + 1 null byte, then UTF-8 JSON
    $valueLen = $msgEnd - $pos
    if ($valueLen -gt 5) {
        $json = [System.Text.Encoding]::UTF8.GetString($smBuffer, $pos + 5, $valueLen - 5).Trim("`0")
        Write-Host "$($pathResult.Text) = $json"
    }

    $pos = $msgEnd
}
```

</details>

## Step 5: Live interaction

Put it in a loop and start interacting with the Prime Go+:

- **Press play** — watch `PlayState` change to `true`
- **Press pause** — watch it change back to `false`
- **Move the crossfader** — watch `CrossfaderPosition` update
- **Load a different track** — watch `SongName` and `ArtistName` change

```powershell
while ($true) {
    $bytesRead = $smStream.Read($smBuffer, 0, $smBuffer.Length)
    if ($bytesRead -eq 0) { break }
    # ... parse and display (same code as step 4)
}
```

<details>
<summary>More paths to try</summary>

```text
/Engine/Deck1/Track/TrackLength
/Engine/Deck1/Track/CurrentKey
/Engine/Deck1/Speed
/Engine/Deck2/Track/SongName
/Engine/Deck2/Track/ArtistName
/Engine/Deck2/CurrentBPM
/Engine/Deck2/PlayState
/Engine/Mixer/Channel1/Volume/Level
```

</details>

## What Success Looks Like

You have a script that connects to the Prime Go+'s StateMap service and displays live DJ data as it changes. You can see track names, BPM, play state, and mixer positions updating in real time in your PowerShell console.

Congratulations — you've reverse engineered a proprietary protocol and built a working client from scratch.

## Next Up

[Milestone 5: Build a StagelinQ Module](milestone-5.md) — Refactor your code into reusable PowerShell functions and build a module together.
