# Milestone 1: Capture and Observe

- **Type:** From captures (self-paced, anytime)
- **Difficulty:** Beginner-friendly entry point
- **Tools needed:** [Wireshark](https://www.wireshark.org) (free)

## Objective

Open a pre-recorded packet capture from a Denon DJ Prime Go+ and examine the raw data it broadcasts on the network. Your goal is to identify patterns in the bytes — what looks like text, where fields begin and end, and what the device might be telling us.

## Background

DJ controllers from Denon use a proprietary protocol called **StagelinQ** to communicate with lighting, video, and effects software over the network. There is no public documentation. Everything we know has been figured out by people doing exactly what you're about to do: staring at bytes in Wireshark.

The Prime Go+ periodically broadcasts UDP packets to announce itself on the network. These "discovery" frames are your starting point.

## What You're Given

- A packet capture file: [`captures/01-discovery-broadcast.pcapng`](../captures/01-discovery-broadcast.pcapng)
- The port number: **UDP 51337**
- This milestone document

That's it. Everything else is for you to figure out.

## Steps

### 1. Open the capture

Open `01-discovery-broadcast.pcapng` in Wireshark. You should see a list of UDP packets. The capture was recorded using the [capture filter](https://wiki.wireshark.org/CaptureFilters) `port 51337`, so it only includes discovery traffic.

### 2. Examine the data

Click on any packet. Below the packet list, Wireshark shows the packet details broken down into expandable layers (Frame, Ethernet II, Internet Protocol, User Datagram Protocol, Data). Click on the **Data** row and Wireshark will highlight the corresponding bytes in the hex dump. This is the StagelinQ discovery payload — the part we care about.

The bytes before the Data section are network headers that your computer uses to deliver the packet. You can ignore them — when we write PowerShell code later, the network stack strips those headers automatically and gives us just the payload.

### 3. Answer these questions

Work through these at your own pace. Write down what you find.

1. **How many distinct packet sizes do you see?** Are all the discovery frames the same length, or are there different sizes?

   <details>
   <summary>Answer</summary>

   Two distinct sizes: 134-byte and 114-byte payloads. The pattern repeats every ~1 second — two 134-byte frames followed by one 114-byte frame.

   </details>

2. **What do the first 4 bytes of every frame have in common?** Select several different frames and compare byte offset 0–3 of the data payload.

   <details>
   <summary>Answer</summary>

   Every frame starts with the same 4 bytes: `0x61 0x69 0x72 0x44` — the ASCII string "airD". These are the magic bytes that identify a StagelinQ discovery frame.

   </details>

3. **Can you spot any readable text?** Look at the ASCII representation on the right side of the hex dump. What words or strings can you make out?

   <details>
   <summary>Answer</summary>

   You should be able to spot strings like "primegoplus", "OfflineAnalyzer", "JP11S", version numbers like "1.0.0" and "4.3.4", and "DISCOVERER_HOWDY_".

   </details>

4. **Compare two different-sized frames.** What's different? What stays the same?

   <details>
   <summary>Answer</summary>

   The magic bytes, device name ("primegoplus"), and connection type ("DISCOVERER_HOWDY_") are the same in both sizes. The difference is the software name and version: 134-byte frames announce "OfflineAnalyzer v1.0.0" and 114-byte frames announce "JP11S v4.3.4" (the Prime Go+ firmware). The 16-byte token also changes with every frame.

   </details>

## What Success Looks Like

You don't need to decode every byte. If you can answer most of the questions above and have a rough mental model of the frame layout, you're ready for Milestone 2.

## Next Up

[Milestone 2: Parse Discovery with PowerShell](milestone-2.md) — Decode the frame structure and write a parser.
