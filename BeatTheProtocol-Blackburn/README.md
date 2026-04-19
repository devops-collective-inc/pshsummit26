# Beat the Protocol

**Reverse Engineering DJ Controller Data Streams with PowerShell**

A Summit Challenge for [PowerShell + DevOps Global Summit 2026](https://www.powershellsummit.org/) (April 13-16, Bellevue, WA).

## What is this?

Denon DJ controllers use a proprietary protocol called **StagelinQ** to broadcast track info, BPM, fader positions, and more over the network. There's no public documentation. In this challenge, you'll reverse engineer the protocol from raw packet captures, decode the data with PowerShell, and — if you're at the Summit in person — connect to a live Denon DJ Prime Go+ and pull real-time data.

## How it works

This is a **self-paced, milestone-based challenge**. Work through the milestones at your own pace — get a head start before the Summit or dive in on day one.

### From captures (anytime — before or during the Summit)

These milestones use pre-recorded packet captures. All you need is Wireshark and PowerShell.

| Milestone | Description |
|-----------|-------------|
| [1. Capture and Observe](milestones/milestone-1.md) | Open a packet capture in Wireshark and find patterns in the raw bytes |
| [2. Parse Discovery with PowerShell](milestones/milestone-2.md) | Decode the frame structure and write a PowerShell parser |

### Live hardware (requires the Prime Go+ on the challenge network)

These milestones connect to a real Denon DJ Prime Go+ during the Summit.

| Milestone | Description |
|-----------|-------------|
| [3. Listen and Connect](milestones/milestone-3.md) | Discover the Prime Go+ on the network and negotiate a session |
| [4. Subscribe to StateMap](milestones/milestone-4.md) | Receive live track names, BPM, and fader positions in real time |
| [5. Build a StagelinQ Module](milestones/milestone-5.md) | Refactor your code into reusable PowerShell functions (collaborative) |

## Getting started

1. Install [Wireshark](https://www.wireshark.org)
2. Open [`captures/01-discovery-broadcast.pcapng`](captures/01-discovery-broadcast.pcapng) in Wireshark
3. Follow [Milestone 1: Capture and Observe](milestones/milestone-1.md)

## What you'll need

- **Wireshark** (free) — for examining packet captures
- **PowerShell 7+** — for writing parsers and network code
- A willingness to stare at hex dumps

## Using AI tools

Feel free to use AI tools like Claude Code, GitHub Copilot, or ChatGPT to help with the challenge. Reverse engineering is as much about asking the right questions as it is about writing code, and knowing how to leverage AI effectively is a practical skill. AI won't replace the learning — you still need to understand what the bytes mean — but it can help you get unstuck, explain unfamiliar concepts, or speed up the coding.

## Repository structure

```text
beat-the-protocol/
├── captures/          # Pre-recorded packet captures (.pcapng)
├── scripts/           # PowerShell scripts and functions
├── milestones/        # Challenge milestone instructions
└── cheatsheet/        # Quick-reference for the protocol
```

## Community implementations

These open-source projects have reverse engineered the StagelinQ protocol. They're great references if you get stuck — or want to go deeper after the challenge.

| Project | Language | Notes |
|---------|----------|-------|
| [chrisle/StageLinq](https://github.com/chrisle/StageLinq) | TypeScript | Most complete. Includes a [Wireshark Lua dissector](https://github.com/chrisle/StageLinq/tree/main/tools/wireshark). |
| [icedream/go-stagelinq](https://github.com/icedream/go-stagelinq) | Go | Mature. Discovery, StateMap, BeatInfo. |
| [Jaxc/PyStageLinQ](https://github.com/Jaxc/PyStageLinQ) | Python | Has detailed [protocol documentation](https://github.com/Jaxc/PyStageLinQ/blob/main/docs/StageLinQ_protocol.md). |

## License

MIT
