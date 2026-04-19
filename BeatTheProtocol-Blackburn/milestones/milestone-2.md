# Milestone 2: Parse Discovery with PowerShell

- **Type:** From captures (self-paced, anytime)
- **Difficulty:** Intermediate
- **Tools needed:** [Wireshark](https://www.wireshark.org) (free), [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)

## Objective

Figure out the structure of a StagelinQ discovery frame using PowerShell, then write a function that parses it. You'll explore the bytes interactively — no field map is given upfront.

## Before You Start

You should have completed [Milestone 1](milestone-1.md). You spotted readable text like "primegoplus" and "OfflineAnalyzer" in the hex dump, and noticed that every frame starts with the same 4 bytes. Now you'll figure out the exact structure and write code to parse it.

## Step 1: Get a payload into PowerShell

Here's the payload from one of the 134-byte frames as a byte array — paste this into your PowerShell session:

```powershell
$bytes = [byte[]]@(
    0x61, 0x69, 0x72, 0x44, 0x86, 0xF4, 0x3E, 0xD3, 0xC2, 0x8F, 0x4B, 0x03, 0xAE, 0x84, 0x38, 0xAE,
    0xDD, 0xFD, 0xFB, 0x1C, 0x00, 0x00, 0x00, 0x16, 0x00, 0x70, 0x00, 0x72, 0x00, 0x69, 0x00, 0x6D,
    0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x70, 0x00, 0x6C, 0x00, 0x75, 0x00, 0x73, 0x00, 0x00,
    0x00, 0x22, 0x00, 0x44, 0x00, 0x49, 0x00, 0x53, 0x00, 0x43, 0x00, 0x4F, 0x00, 0x56, 0x00, 0x45,
    0x00, 0x52, 0x00, 0x45, 0x00, 0x52, 0x00, 0x5F, 0x00, 0x48, 0x00, 0x4F, 0x00, 0x57, 0x00, 0x44,
    0x00, 0x59, 0x00, 0x5F, 0x00, 0x00, 0x00, 0x1E, 0x00, 0x4F, 0x00, 0x66, 0x00, 0x66, 0x00, 0x6C,
    0x00, 0x69, 0x00, 0x6E, 0x00, 0x65, 0x00, 0x41, 0x00, 0x6E, 0x00, 0x61, 0x00, 0x6C, 0x00, 0x79,
    0x00, 0x7A, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x31, 0x00, 0x2E, 0x00, 0x30,
    0x00, 0x2E, 0x00, 0x30, 0x81, 0xD5
)
```

This is the same data you saw in Wireshark — each `0x` value is one byte. When you receive live packets in later milestones, the network stack gives you a byte array directly, so this is the format you'll always be working with.

Verify it loaded correctly:

```powershell
"$($bytes.Length) bytes, starts with: $([System.Text.Encoding]::ASCII.GetString($bytes, 0, 4))"
```

You should see: `134 bytes, starts with: airD`

Now `$bytes` is a byte array you can index into — `$bytes[0]` is the first byte, `$bytes[1]` is the second, and so on.

## Step 2: Explore the magic bytes

You just verified the first 4 bytes are "airD". Here's how that worked:

```powershell
[System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
```

The `0` is the starting index in the byte array and `4` is how many bytes to read. These 4 bytes identify this as a StagelinQ discovery frame. Every discovery frame starts with them.

That accounts for bytes 0–3. What about the rest?

## Step 3: Find the text

From Milestone 1, you know "primegoplus" is in these frames somewhere. You also noticed `0x00` between every letter — that means the text is encoded as **UTF-16 Big Endian** (2 bytes per character). Let's find it.

Try decoding everything after the magic bytes as UTF-16BE:

```powershell
[System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 4, $bytes.Length - 4)
```

You should see "primegoplus" in the output, along with other readable strings and garbage characters. The readable text doesn't start right at index 4 — there's something else before it.

Try starting at different indices until "primegoplus" appears cleanly. Where does it start?

<details>
<summary>Answer</summary>

It starts at index 24:

```powershell
[System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 24, 22)
```

That gives you `primegoplus` — 11 characters x 2 bytes each = 22 bytes.

</details>

So bytes 4–23 are not readable text. We'll come back to those. First, let's figure out how the protocol tells us where the string starts and how long it is.

Look at the 4 bytes right before "primegoplus" — indices 20 through 23:

```powershell
$bytes[20..23]
```

You should see `0, 0, 0, 22`. The string is 22 bytes long, and right before it is the number 22. The protocol puts the **byte length of the string** right before it — a 4-byte **big-endian integer** (most significant byte first). This is called a length prefix.

That means bytes 4–19 (the 16 bytes between the magic and the first length prefix) are something else. In the StagelinQ protocol, this is a 128-bit identifier called the **token**.

## Step 4: Keep going — find the next field

You've discovered the pattern: **4-byte length prefix followed by a UTF-16BE string**. The device name started at index 20 and used 4 + 22 = 26 bytes, so the next field should start at index 46.

Try it:

```powershell
# Read the length prefix at index 46
$bytes[46..49]
```

<details>
<summary>What's the length?</summary>

`0, 0, 0, 34` — the next string is 34 bytes long.

</details>

Now read that string:

```powershell
[System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 50, 34)
```

<details>
<summary>What do you get?</summary>

```text
DISCOVERER_HOWDY_
```

This is the connection type — the device is saying hello.

</details>

Keep applying the same pattern. After this 34-byte string (index 50 + 34 = 84), what's the next length prefix? What string follows it? And after that?

<details>
<summary>Remaining fields</summary>

Starting at index 84: length = 30, string = "OfflineAnalyzer" (the software name)

Starting at index 118: length = 10, string = "1.0.0" (the software version)

</details>

## Step 5: The last 2 bytes

After the four strings, there are 2 bytes left at the end of the array. These aren't a string — try reading them as a **big-endian 16-bit integer**:

```powershell
([int]$bytes[132] -shl 8) + $bytes[133]
```

<details>
<summary>What's the value?</summary>

```text
33237
```

This is a TCP port number — the port a client would connect to for a full StagelinQ session. You'll use this in [Milestone 3](milestone-3.md).

</details>

## Step 6: The complete field map

You've now decoded the entire frame. Here's the structure you discovered:

```text
Field              Size        Encoding
Magic bytes        4 bytes     ASCII "airD"
Token              16 bytes    128-bit identifier for this announcement
Device Name        4+N bytes   Length-prefixed UTF-16BE string
Connection Type    4+N bytes   Length-prefixed UTF-16BE string
Software Name      4+N bytes   Length-prefixed UTF-16BE string
Software Version   4+N bytes   Length-prefixed UTF-16BE string
Service Port       2 bytes     Big-endian unsigned 16-bit integer
```

## Step 7: Write the parser

Now put it all together as a reusable function. You need to:

1. Verify the magic bytes
2. Extract the 16-byte token
3. Read four length-prefixed strings in order
4. Read the last 2 bytes as a port number

Since you're reading length-prefixed strings four times, a helper function will save you from repeating code. Think about what the length-prefix reading code from step 3 would look like as a reusable function that returns both the decoded string and the next index to read from.

<details>
<summary>Hint: helper function</summary>

```powershell
function Read-PrefixedString {
    param([byte[]]$Data, [int]$Offset)

    $lengthBytes = $Data[$Offset..($Offset + 3)]
    [Array]::Reverse($lengthBytes)
    $length = [System.BitConverter]::ToUInt32($lengthBytes, 0)

    $text = [System.Text.Encoding]::BigEndianUnicode.GetString($Data, $Offset + 4, $length)

    [PSCustomObject]@{
        Text      = $text
        NewOffset = $Offset + 4 + $length
    }
}
```

</details>

<details>
<summary>Full solution</summary>

```powershell
function Read-PrefixedString {
    param([byte[]]$Data, [int]$Offset)

    $lengthBytes = $Data[$Offset..($Offset + 3)]
    [Array]::Reverse($lengthBytes)
    $length = [System.BitConverter]::ToUInt32($lengthBytes, 0)

    $text = [System.Text.Encoding]::BigEndianUnicode.GetString($Data, $Offset + 4, $length)

    [PSCustomObject]@{
        Text      = $text
        NewOffset = $Offset + 4 + $length
    }
}

function Read-DiscoveryFrame {
    param([byte[]]$Data)

    # Verify magic bytes
    $magic = [System.Text.Encoding]::ASCII.GetString($Data, 0, 4)
    if ($magic -ne 'airD') {
        throw "Not a StagelinQ discovery frame (magic: $magic)"
    }

    # Token (bytes 4-19)
    $token = [BitConverter]::ToString($Data[4..19]) -replace '-', ''

    # Four length-prefixed strings starting after the magic and token
    $offset = 20
    $deviceName = Read-PrefixedString -Data $Data -Offset $offset
    $offset = $deviceName.NewOffset

    $connectionType = Read-PrefixedString -Data $Data -Offset $offset
    $offset = $connectionType.NewOffset

    $softwareName = Read-PrefixedString -Data $Data -Offset $offset
    $offset = $softwareName.NewOffset

    $softwareVersion = Read-PrefixedString -Data $Data -Offset $offset
    $offset = $softwareVersion.NewOffset

    # Service port (last 2 bytes, big-endian uint16)
    $port = ([int]$Data[$offset] -shl 8) + $Data[$offset + 1]

    [PSCustomObject]@{
        DeviceName      = $deviceName.Text
        ConnectionType  = $connectionType.Text
        SoftwareName    = $softwareName.Text
        SoftwareVersion = $softwareVersion.Text
        ServicePort     = $port
        Token           = $token
    }
}
```

</details>

## Step 8: Test it

Run your parser against the payload:

```powershell
Read-DiscoveryFrame -Data $bytes
```

<details>
<summary>Expected output</summary>

```text
DeviceName      : primegoplus
ConnectionType  : DISCOVERER_HOWDY_
SoftwareName    : OfflineAnalyzer
SoftwareVersion : 1.0.0
ServicePort     : 33237
Token           : 86F43ED3C28F4B03AE8438AEDDFDFB1C
```

</details>

## Step 9: Validate with the Wireshark dissector

The [chrisle/StageLinq](https://github.com/chrisle/StageLinq) project includes a Lua dissector that parses discovery frames automatically. Install it following the [installation instructions](https://github.com/chrisle/StageLinq/blob/main/tools/wireshark/README.md), restart Wireshark, and reopen the capture. Compare the dissector's output to your parser's output — they should match.

## What Success Looks Like

You have a working `Read-DiscoveryFrame` function that takes a byte array and returns a structured object with the device name, connection type, software name, version, service port, and token.

## Next Up

[Milestone 3: Listen and Connect](milestone-3.md) — Discover the Prime Go+ on the network and negotiate a session.
