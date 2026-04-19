# Scripts

Example PowerShell scripts for working with the StagelinQ protocol. These were developed during the creation of this challenge and can serve as reference or inspiration.

## Files

| Script | Description |
|--------|-------------|
| `Test-Discovery.ps1` | Simple UDP listener that receives and displays live discovery broadcasts from the Prime Go+. |
| `Connect-StagelinQ.ps1` | Complete end-to-end client: announces on the network, discovers the device, connects to the directory server, subscribes to StateMap paths, and displays live state data (track name, artist, BPM, play state, crossfader). |
| `Capture-FullSession.ps1` | Runs a full StagelinQ session while you capture traffic in Wireshark. Used to generate the packet captures in the `captures/` folder. |
