# StagelinQ Quick Reference

## Protocol Layers

```text
UDP 51337 (broadcast)          TCP (dynamic ports)           TCP (dynamic ports)
┌──────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│    Discovery     │ ──> │   Directory Server    │ ──> │      Services       │
│  Magic: "airD"   │     │  Service list + ports  │     │  StateMap, BeatInfo │
└──────────────────┘     └──────────────────────┘     └─────────────────────┘
```

## Discovery Frame (UDP)

```text
Field              Size        Encoding
Magic              4 bytes     ASCII "airD" (0x61697244)
Token              16 bytes    128-bit identifier
Device Name        4+N bytes   Length-prefixed UTF-16BE
Connection Type    4+N bytes   Length-prefixed UTF-16BE
Software Name      4+N bytes   Length-prefixed UTF-16BE
Software Version   4+N bytes   Length-prefixed UTF-16BE
Service Port       2 bytes     Big-endian uint16
```

Connection types: `DISCOVERER_HOWDY_` (announce), `DISCOVERER_EXIT_` (leave)

## Directory Server Messages (TCP)

| Type | Name | Payload |
|------|------|---------|
| `0x00000002` | Services Request | 16-byte token |
| `0x00000001` | Timestamp | 16-byte token + 16-byte token2 + 8-byte uptime (nanoseconds, big-endian) |
| `0x00000000` | Service Announcement | 16-byte token + length-prefixed UTF-16BE service name + 2-byte big-endian port |

**Handshake sequence:**
1. Announce yourself via UDP (`DISCOVERER_HOWDY_`)
2. TCP connect to the device's service port
3. Wait — device sends Services Request first
4. Respond with your own Services Request (`0x00000002` + your token)
5. Device sends Service Announcements

## Available Services

| Service | Description |
|---------|-------------|
| StateMap | Live state data (track info, BPM, fader positions) |
| BeatInfo | Real-time beat position and timing |
| Broadcast | Broadcast messaging |
| TimeSynchronization | Clock sync between devices |
| FileTransfer | Access to the device's file system |

## StateMap Protocol

**Magic:** `smaa` (`0x736D6161`)

### Connection frame

```text
Message type     4 bytes     0x00000000 (big-endian)
Token            16 bytes    Your token
Service name     4+N bytes   "StateMap" as length-prefixed UTF-16BE
Port             2 bytes     0x0000
```

### Subscription frame

```text
Total length     4 bytes     Big-endian uint32 (byte count of everything below)
Magic            4 bytes     "smaa" (0x736D6161)
Type             4 bytes     0x000007D2
Path length      4 bytes     Big-endian uint32
Path             N bytes     UTF-16BE encoded state path
Delimiter        4 bytes     0x00000000
```

### State value response

```text
Total length     4 bytes     Big-endian uint32
Magic            4 bytes     "smaa" (0x736D6161)
Type             4 bytes     Big-endian uint32
Path             4+N bytes   Length-prefixed UTF-16BE state path
Value length     4 bytes     Big-endian uint32
Null byte        1 byte      0x00
JSON             N bytes     UTF-8 encoded JSON value
```

### JSON value types

| Type | Format | Example |
|------|--------|---------|
| 0 | Float | `{"type":0,"value":124.86}` |
| 1 | Boolean | `{"state":true,"type":1}` |
| 8 | String | `{"string":"Song Name","type":8}` |
| 10 | Integer | `{"type":10,"value":67}` |

## StateMap Paths

Replace `%1` with the deck number (1–4).

### Most Useful Paths

```text
/Engine/Deck%1/Track/SongName
/Engine/Deck%1/Track/ArtistName
/Engine/Deck%1/CurrentBPM
/Engine/Deck%1/PlayState
/Engine/Deck%1/Track/TrackLength
/Engine/Deck%1/Track/CurrentKey
/Engine/Deck%1/Speed
/Engine/Mixer/CrossfaderPosition
/Engine/Mixer/Channel%1/Volume/Level
```

### Playback

```text
/Engine/Deck%1/PlayState
/Engine/Deck%1/Play
/Engine/Deck%1/CurrentBPM
/Engine/Deck%1/Speed
/Engine/Deck%1/SpeedState
/Engine/Deck%1/SpeedRange
/Engine/Deck%1/DeckIsMaster
/Engine/Deck%1/SyncMode
/Engine/Deck%1/BeatNumber
```

### Track Metadata

```text
/Engine/Deck%1/Track/SongName
/Engine/Deck%1/Track/ArtistName
/Engine/Deck%1/Track/TrackName
/Engine/Deck%1/Track/TrackUri
/Engine/Deck%1/Track/SongLoaded
/Engine/Deck%1/Track/TrackLength
/Engine/Deck%1/Track/SampleRate
/Engine/Deck%1/Track/MetaDataBPM
```

### Position and Timing

```text
/Engine/Deck%1/Track/PlayPosition
/Engine/Deck%1/Track/SongPosition
/Engine/Deck%1/Track/RemainingTime
/Engine/Deck%1/Track/BarsElapsed
/Engine/Deck%1/Track/CuePosition
```

### Tempo and Key

```text
/Engine/Deck%1/Track/CurrentBPM
/Engine/Deck%1/Track/OriginalTempo
/Engine/Deck%1/Track/CurrentKey
/Engine/Deck%1/Track/CurrentKeyIndex
/Engine/Deck%1/Track/KeyLock
```

### Mixer

```text
/Engine/Mixer/CrossfaderPosition
/Engine/Mixer/CrossfaderCurve
/Engine/Mixer/EnableXfader
/Engine/Mixer/Channel%1/Volume/Level
/Engine/Mixer/Channel%1/PFL
/Engine/Mixer/Channel%1/DJFx/Active
/Engine/Mixer/DJFxEnabled
/Engine/Mixer/Recorder/Active
/Engine/Mixer/Recorder/RecordTime
```

### Master and Sync

```text
/Engine/Master/MasterTempo
/Engine/Master/QuantizeEnabled
/Engine/Sync/Network/SyncType
/Engine/Sync/Network/EnableAbletonLink
/Engine/Sync/Network/AbletonLink/Tempo
/Engine/Sync/Network/AbletonLink/NumPeers
```

### Sampler

```text
/Engine/Sampler%1/Play
/Engine/Sampler%1/Loaded
/Engine/Sampler%1/TrackName
/Engine/Sampler%1/Volume/Level
```

### System

```text
/Engine/DeckCount
/Engine/Silent
```
