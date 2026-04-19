# Milestone 3: Listen and Connect

- **Type:** Live hardware (requires the Prime Go+ on the challenge network)
- **Difficulty:** Intermediate
- **Tools needed:** [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell), [Wireshark](https://www.wireshark.org) (free)

## Objective

Receive live discovery broadcasts from the Prime Go+, connect to its directory server, and retrieve the list of services it offers. By the end you'll have a script that discovers the device on the network and negotiates a session with it.

## Before You Start

You should have completed [Milestone 2](milestone-2.md). You'll need your `Read-DiscoveryFrame` and `Read-PrefixedString` functions — paste them into your PowerShell session or dot-source a script file.

You'll also need your laptop connected to the challenge network (the same network the Prime Go+ is on).

## Step 1: Receive live discovery

In Milestone 2, you parsed a static byte array. Now you'll receive live bytes from the network.

Create a `UdpClient` that listens on port 51337 and use your `Read-DiscoveryFrame` function to parse whatever arrives:

```powershell
$udpClient = [System.Net.Sockets.UdpClient]::new(51337)
$endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)

$bytes = $udpClient.Receive([ref]$endpoint)
$frame = Read-DiscoveryFrame -Data $bytes
$frame
```

On Windows, the firewall may prompt to allow PowerShell network access — click Allow.

If you get an error about port 51337 being blocked ("access permissions" or "address already in use"), close all PowerShell windows and try again in a fresh session. Windows sometimes reserves port ranges that include 51337 — a reboot will clear this if closing windows doesn't help.

<details>
<summary>What do you get?</summary>

Your parser from Milestone 2 should work on the live data with no changes. You'll see the same fields — DeviceName, ConnectionType, SoftwareName, SoftwareVersion, ServicePort, and Token — but with real values from the Prime Go+ on the network.

</details>

Note the **ServicePort** value and the device's **IP address** (from `$endpoint.Address`). You'll need both for the next step.

## Step 2: Try connecting

You have a TCP port from the discovery frame. Try connecting to it:

```powershell
$tcp = [System.Net.Sockets.TcpClient]::new()
$tcp.Connect($endpoint.Address.ToString(), $frame.ServicePort)
$stream = $tcp.GetStream()
$stream.ReadTimeout = 5000

$buffer = [byte[]]::new(4096)
$bytesRead = $stream.Read($buffer, 0, $buffer.Length)
Write-Output "Received $bytesRead bytes"
```

<details>
<summary>What happens?</summary>

The connection opens but immediately closes — you receive 0 bytes. The device rejected you.

If you open `captures/04-failed-connect.pcapng` in Wireshark and look at the TCP packets, you'll see: SYN → SYN-ACK → ACK (connection established), then immediately FIN (device closes). The device accepted the TCP handshake but refused to communicate.

</details>

Why? The StagelinQ protocol uses a **peer-to-peer discovery pattern**. Devices only communicate with peers they've seen announce themselves on the network. Think of it like joining a conversation — you have to introduce yourself before anyone will talk to you.

The Prime Go+ broadcasts its discovery announcements, but it's also *listening* for other devices to announce. Since we haven't announced, the device doesn't recognize us as a peer and closes the connection.

## Step 3: Announce yourself

You already know the discovery frame format from Milestone 2. Now you need to build one and broadcast it.

Generate a random 16-byte token to identify yourself:

```powershell
$token = [byte[]]::new(16)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($token)
$token[0] = $token[0] -band 0x7F  # Clear the most significant bit
```

Build a discovery frame with your token. You need:
- Magic bytes: `airD`
- Your token
- A source name (any name, like `"powershell"`)
- Action: `DISCOVERER_HOWDY_`
- A software name (any name, like `"challenge"`)
- A version (like `"1.0.0"`)
- Port: `0` (we're not offering services)

<details>
<summary>Hint: building the frame</summary>

Use a `MemoryStream` and `BinaryWriter` to construct the bytes. For each length-prefixed UTF-16BE string, write a 4-byte big-endian length followed by the encoded string bytes — the same format you parsed in Milestone 2, but in reverse.

```powershell
$ms = [System.IO.MemoryStream]::new()
$bw = [System.IO.BinaryWriter]::new($ms)

# Magic
$bw.Write([System.Text.Encoding]::ASCII.GetBytes('airD'))

# Token
$bw.Write($token)

# For each string field, write length-prefixed UTF-16BE
foreach ($str in @('powershell', 'DISCOVERER_HOWDY_', 'challenge', '1.0.0')) {
    $strBytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes($str)
    $lenBytes = [BitConverter]::GetBytes([uint32]$strBytes.Length)
    [Array]::Reverse($lenBytes)
    $bw.Write($lenBytes)
    $bw.Write($strBytes)
}

# Port (2 bytes, big-endian)
$bw.Write([byte]0)
$bw.Write([byte]0)

$bw.Flush()
[byte[]]$announceFrame = $ms.ToArray()
$bw.Close(); $ms.Close()
```

</details>

Broadcast your announcement:

```powershell
$announceSocket = [System.Net.Sockets.UdpClient]::new()
$announceSocket.EnableBroadcast = $true
$broadcastEp = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Broadcast, 51337)

$announceSocket.Send($announceFrame, $announceFrame.Length, $broadcastEp)
```

You need to keep announcing periodically — the device expects to see regular announcements. Send one every second or so.

## Step 4: Connect again

After announcing a few times, try the TCP connection again. This time, don't send anything — just read:

```powershell
$tcp = [System.Net.Sockets.TcpClient]::new()
$tcp.Connect($endpoint.Address.ToString(), $frame.ServicePort)
$stream = $tcp.GetStream()
$stream.ReadTimeout = 10000

$buffer = [byte[]]::new(4096)
$bytesRead = $stream.Read($buffer, 0, $buffer.Length)
Write-Output "Received $bytesRead bytes"
```

<details>
<summary>What happens?</summary>

This time you receive 20 bytes! The device speaks first. It sent you a message.

</details>

## Step 5: Parse the directory server messages

The device is sending you messages. Each message starts with a 4-byte big-endian message type — the same pattern you've been working with since Milestone 2.

Here are the message types:

| Type | Name | Payload |
|------|------|---------|
| `0x00000002` | Services Request | 16-byte token |
| `0x00000001` | Timestamp | 16-byte token + 16-byte token2 + 8-byte uptime (nanoseconds, big-endian) |
| `0x00000000` | Service Announcement | 16-byte token + length-prefixed UTF-16BE service name + 2-byte big-endian port |

The first message you receive should be a **Services Request** — the device is asking "what services do you have?" Parse it: read the 4-byte message type, then read the 16-byte token.

To get the device to list *its* services, send back a Services Request of your own — the same format: 4-byte message type (`0x00000002`) + your 16-byte token:

```powershell
$request = [byte[]]::new(20)
$request[3] = 0x02  # Message type 0x00000002
[Array]::Copy($token, 0, $request, 4, 16)
$stream.Write($request, 0, $request.Length)
$stream.Flush()
```

Now read the response. The device will send multiple **Service Announcement** messages — each one names a service and gives its TCP port. Parse them using the same length-prefixed UTF-16BE string reading you wrote in Milestone 2.

<details>
<summary>What services do you see?</summary>

The Prime Go+ announces these services:
- **StateMap** — live state data (track info, BPM, fader positions)
- **BeatInfo** — real-time beat position and timing
- **Broadcast** — broadcast messaging
- **TimeSynchronization** — clock sync between devices
- **FileTransfer** — access to the device's file system

Each has a dynamically assigned TCP port.

</details>

You can also open `captures/02-full-session.pcapng` in Wireshark to see this exchange — the directory server handshake starts at the first TCP SYN packet.

## What Success Looks Like

You have a script that:
1. Announces itself on the network
2. Discovers the Prime Go+
3. Connects to the directory server
4. Retrieves and displays the list of available services and their ports

## Next Up

[Milestone 4: Subscribe to StateMap](milestone-4.md) — Connect to the StateMap service and receive live DJ data.
