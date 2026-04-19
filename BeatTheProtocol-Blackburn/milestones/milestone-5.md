# Milestone 5: Build a StagelinQ Module

- **Type:** Live hardware (requires the Prime Go+ on the challenge network)
- **Difficulty:** Advanced
- **Tools needed:** [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)

## Objective

Turn your working scripts into a proper PowerShell module. You've been writing inline code throughout the challenge — now refactor it into reusable functions that anyone can import and use. This is a collaborative milestone: divide the work with other participants and build the module together.

## Before You Start

You should have completed [Milestone 4](milestone-4.md) and have working code that announces, discovers, connects to the directory server, retrieves services, connects to StateMap, subscribes to paths, and displays live data.

## The Vision

Imagine being able to do this:

```powershell
Import-Module StagelinQ

$device = Connect-StagelinQDevice
$stateMap = Connect-StagelinQStateMap -Device $device

Register-StateMapPath -Connection $stateMap -Path '/Engine/Deck1/Track/SongName'
Register-StateMapPath -Connection $stateMap -Path '/Engine/Deck1/CurrentBPM'

Watch-StagelinQState -Connection $stateMap
```

That's the goal. Each line maps to a function that encapsulates the protocol knowledge you've built up.

## Suggested Functions

Here's a breakdown of functions that would make a complete module. Pick one or two to build — you don't need to write all of them.

### Discovery and Announcement

| Function | Description | Built from |
|----------|-------------|------------|
| `Read-DiscoveryFrame` | Parse a discovery frame byte array into a structured object | Milestone 2 |
| `Send-StagelinQAnnouncement` | Broadcast a discovery frame with your token | Milestone 3, Step 3 |
| `Find-StagelinQDevice` | Listen for discovery broadcasts and return device info | Milestone 3, Step 1 |

### Connection

| Function | Description | Built from |
|----------|-------------|------------|
| `Connect-StagelinQDevice` | Announce, discover, and complete the directory server handshake. Return a connection object with the service list. | Milestone 3 |
| `Get-StagelinQService` | Given a device connection, return the list of available services and their ports | Milestone 3, Step 5 |
| `Disconnect-StagelinQDevice` | Send a `DISCOVERER_EXIT_` announcement and close connections | New |

### StateMap

| Function | Description | Built from |
|----------|-------------|------------|
| `Connect-StagelinQStateMap` | Connect to the StateMap service port and send the connection frame | Milestone 4, Step 2 |
| `Register-StateMapPath` | Build and send a subscription for one or more state paths | Milestone 4, Step 3 |
| `Read-StateMapValue` | Read and parse a single state message from the stream | Milestone 4, Step 4 |
| `Watch-StagelinQState` | Subscribe to paths and continuously display state updates | Milestone 4, Step 5 |

### Helpers

| Function | Description | Built from |
|----------|-------------|------------|
| `Read-PrefixedString` | Read a length-prefixed UTF-16BE string from a byte array | Milestone 2 |
| `Write-PrefixedString` | Write a length-prefixed UTF-16BE string to a BinaryWriter | Milestone 3, Step 3 |

## Tips for Building Functions

- **Use `[PSCustomObject]` for return values.** Your functions should return structured objects, not write directly to the console. For example, `Read-StateMapValue` should return an object with `Path` and `Value` properties.

- **Accept pipeline input where it makes sense.** `Register-StateMapPath` could accept paths from the pipeline: `'/Engine/Deck1/PlayState', '/Engine/Deck1/CurrentBPM' | Register-StateMapPath -Connection $stateMap`

- **Use approved verbs.** PowerShell has a set of [approved verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands) (`Get-`, `Set-`, `Connect-`, `Read-`, `Write-`, etc.). The function names above follow this convention.

- **Add comment-based help.** Even a one-liner `.SYNOPSIS` makes your function discoverable with `Get-Help`.

## Collaborate

This milestone works best as a team effort. Coordinate in the Summit Challenge Slack channel:

- Claim a function you want to build
- Share your code when it's working
- Test each other's functions
- Assemble the pieces into a module

## What Success Looks Like

You've contributed one or more polished PowerShell functions that encapsulate part of the StagelinQ protocol. Together with other participants, you've built the foundation of a reusable PowerShell module for communicating with Denon DJ hardware.
