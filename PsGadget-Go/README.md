# PsGadget — From Scripts to Circuits: PowerShell for Hardware Hackers

**Speaker:** Mark Go
**Session:** PowerShell + DevOps Global Summit 2026

> "Let's play in serial bus traffic"

## Abstract

PowerShell can do more than automate servers — it can talk directly to hardware. This session explores how to use the FTDI FT232H breakout board and the **PsGadget** PowerShell module to control GPIO pins, drive stepper motors, scan I²C buses, and push pixels to an OLED display — all from within PowerShell, with no firmware to deploy.

We'll cover how USB-to-serial chips work, what MPSSE is and why it matters, and why PowerShell makes a surprisingly capable hardware control layer. Live demos include driving a toy tank via GPIO and writing to a 128×64 OLED display.

## What's Included

```
slides/
  PsGadget-Go.html    — rendered slide deck (open in browser)
  PsGadget-Go.md      — Marp source
  summit-2026.css     — theme stylesheet
  images/             — all images referenced in slides

demo/
  Start-PsGadgetDemo.ps1   — main demo script
  Start-TestDemo.ps1        — environment test script
  espnow_controller.py      — MicroPython ESPNow controller
  espnow_receiver.py        — MicroPython ESPNow receiver
  espnow_sender.py          — MicroPython ESPNow sender
```

## Getting Started

```powershell
Install-Module PsGadget

Import-Module PsGadget
Test-PsGadgetEnvironment
```

**Hardware used in demos:**
- Adafruit FT232H breakout board (~$20)
- FT232R breakout board (~$7)
- SSD1306 OLED display (I²C, 128×64)
- RC toy tank (RF remote repurposed)

## Links

- **PsGadget module:** `Install-Module PsGadget`
- **GitHub:** https://github.com/markgzero/psgadget
- **mpremote:** `pip install mpremote`
