#Requires -Version 7.0
<#
.SYNOPSIS
    PSGadget live demo runner — Demo 2 (Tank GPIO) and Demo 3 (SSD1306 I2C display).

.DESCRIPTION
    Uses a single FT232H (SN: FTAXBFCQ).
    Demo 2: pulses GPIO pins wired to the tank remote PCB (LOW = button press).
    Demo 3: I2C scan, then writes to SSD1306 OLED at 0x3C.

.PARAMETER Demo
    Which demo(s) to run: 2, 3, or 'all'. Default = 'all'.

.EXAMPLE
    .\Start-TestDemo.ps1
    .\Start-TestDemo.ps1 -Demo 2
    .\Start-TestDemo.ps1 -Demo 3
#>
[CmdletBinding()]
param(
    [ValidateSet('2', '3', 'all')]
    [string]$Demo = 'all'
)

Import-Module PSGadget -ErrorAction Stop

$SN = 'FTAXBFCQ'

# Pin map — tank remote PCB, LOW = button press
$pinMap = @{
    Forward     = 2
    Reverse     = 3
    RotateLeft  = 0
    RotateRight = 1
    SoundMode   = 4   # cycles: silent -> fx only -> music + fx
    SpeedMode   = 5   # cycles: slow -> fast
    Laser       = 6   # 3 sec cooldown
    MainGun     = 7   # 5 sec cooldown
}

function Invoke-Demo2 {
    param([object]$dev)
    Write-Host "`n=== Demo 2 — Tank GPIO ===" -ForegroundColor Cyan

    # Helper: pulse one pin LOW for $ms milliseconds (simulates button press)
    function Press([int]$pin, [int]$ms = 300) {
        $dev.PulsePin($pin, 'LOW', $ms)
        Start-Sleep -Milliseconds 100   # brief gap between presses
    }

    Write-Host "  Speed mode: fast" -ForegroundColor Gray
    Press $pinMap.SpeedMode

    Write-Host "  Forward 600 ms" -ForegroundColor Gray
    Press $pinMap.Forward 600

    Write-Host "  Rotate right 400 ms" -ForegroundColor Gray
    Press $pinMap.RotateRight 400

    Write-Host "  Forward 600 ms" -ForegroundColor Gray
    Press $pinMap.Forward 600

    Write-Host "  Rotate left 400 ms" -ForegroundColor Gray
    Press $pinMap.RotateLeft 400

    Write-Host "  Laser" -ForegroundColor Gray
    Press $pinMap.Laser

    Write-Host "  Main gun" -ForegroundColor Gray
    Press $pinMap.MainGun

    Write-Host "  Reverse 400 ms" -ForegroundColor Gray
    Press $pinMap.Reverse 400

    Write-Host "Demo 2 complete." -ForegroundColor Green
}

function Invoke-Demo3 {
    param([object]$dev)
    Write-Host "`n=== Demo 3 — I2C / SSD1306 Display ===" -ForegroundColor Cyan

    # I2C scan
    Write-Host "  Scanning I2C bus..." -ForegroundColor Gray
    $found = $dev.scanI2CBus()
    if ($found.Count -eq 0) {
        Write-Warning "  No I2C devices found — check wiring and pull-ups."
        return
    }
    foreach ($d in $found) {
        Write-Host ("  Found: {0}" -f $d.Hex) -ForegroundColor Gray
    }

    # Display
    if (-not ($found | Where-Object { $_.Address -eq 0x3C })) {
        Write-Warning "  SSD1306 not found at 0x3C — skipping display demo."
        return
    }

    Write-Host "  Initializing SSD1306 at 0x3C..." -ForegroundColor Gray
    $disp = $dev.GetDisplay()

    $disp.Clear() | Out-Null

    $disp.WriteText('PSGadget', 0, 'center', 2, $false) | Out-Null
    $disp.WriteText('PS + FT232H', 4, 'center') | Out-Null
    Start-Sleep -Seconds 2

    $disp.Clear() | Out-Null
    $disp.WriteText('Demo 3', 0, 'center', 2, $false) | Out-Null
    $disp.WriteText('I2C over MPSSE', 4, 'center') | Out-Null
    Start-Sleep -Seconds 2

    $disp.Clear() | Out-Null
    $disp.WriteText('PSummit 2026', 2, 'center') | Out-Null
    Start-Sleep -Seconds 2

    $dev.ClearDisplay() | Out-Null
    Write-Host "Demo 3 complete." -ForegroundColor Green
}

# ── Main ────────────────────────────────────────────────────────────────────

$dev = $null
try {
    Write-Host "Connecting to FT232H ($SN)..." -ForegroundColor DarkGray
    $dev = New-PsGadgetFtdi -SerialNumber $SN

    if ($Demo -eq '2' -or $Demo -eq 'all') { Invoke-Demo2 $dev }
    if ($Demo -eq '3' -or $Demo -eq 'all') { Invoke-Demo3 $dev }

} catch {
    Write-Error "Demo failed: $_"
} finally {
    if ($dev) {
        $dev.Close()
        Write-Host "`nDevice closed." -ForegroundColor DarkGray
    }
}
