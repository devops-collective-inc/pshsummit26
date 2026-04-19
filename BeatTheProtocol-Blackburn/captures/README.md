# Packet Captures

Pre-recorded network captures from a Denon DJ Prime Go+ for use in the Summit Challenge milestones.

## Files

| File | Description |
|------|-------------|
| `01-discovery-broadcast.pcapng` | UDP discovery broadcasts only. 15 packets (~5 seconds). |
| `02-full-session.pcapng` | Complete protocol lifecycle: UDP announce/discover, TCP directory server handshake, StateMap connection and state snapshot. |
| `03-active-session.pcapng` | StateMap session with live interactions: play/pause, track loading, crossfader movement. |
| `04-failed-connect.pcapng` | TCP connection attempt without announcing first — device immediately closes the connection. |

## How to use

1. Install [Wireshark (free, cross-platform)](https://www.wireshark.org).
2. Open any `.pcapng` file in Wireshark.
