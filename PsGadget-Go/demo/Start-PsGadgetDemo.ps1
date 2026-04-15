#Requires -Version 7.0
Import-Module PSGadget -ErrorAction Stop

#Region Config
$SN_Tank    = 'FT9ZLJ51'   # FT232H → GPIO → RC tank remote PCB
$SN_Display = 'DS8VYR6K'   # FT232H → I2C → SSD1306 OLED (0x3C)
$SN_Turret  = 'FTAXBFCQ'   # FT232H → I2C → PCA9685 servo driver (0x40)
                            #   ch0 = pan   ch3 = tilt
$SN_Stepper = 'CT9UMHFA'   # FT232H → ACBUS → ULN2003 stepper driver

$pin = @{
    Reverse = 0
    Forward = 1
    Left    = 2
    Right   = 3
    Laser   = 6
    MainGun = 7
}
#EndRegion

$tank    = $null
$ssd1306 = $null
$turret  = $null
$stepper = $null
$d       = $null

function Set-Turret {
    param([int]$Pan, [int]$Tilt)
    Invoke-PsGadgetI2C -I2CModule PCA9685 -ServoAngle ((0, $Pan), (3, $Tilt)) -PsGadget $turret | Out-Null
}

try {
    Write-Output "Connecting to tank    ($SN_Tank)..."
    $tank = New-PsGadgetFtdi -SerialNumber $SN_Tank
    Write-Output "  Tank ready."

    Write-Output "Connecting to display ($SN_Display)..."
    $ssd1306 = New-PsGadgetFtdi -SerialNumber $SN_Display
    $ssd1306.ScanI2CBus() | Out-Null
    $d = $ssd1306.GetDisplay()
    Write-Output "  Display ready."

    Write-Output "Connecting to turret  ($SN_Turret)..."
    $turret = New-PsGadgetFtdi -SerialNumber $SN_Turret
    $turret.ScanI2CBus() | Out-Null
    Write-Output "  Turret ready."

    Write-Output "Connecting to stepper ($SN_Stepper)..."
    $stepper = New-PsGadgetFtdi -SerialNumber $SN_Stepper
    Write-Output "  Stepper ready."

    # Intro
    Write-Output "`n[INTRO]"
    $d.ShowSplash()
    Start-Sleep -Seconds 2
    $d.Clear() | Out-Null
    $d.WriteText('PSummit 2026', 2, 'center') | Out-Null
    Start-Sleep -Seconds 2

    # Center turret
    Set-Turret -Pan 90 -Tilt 80

    # --- sequence ---
    Write-Output "`n[SEQUENCE START]"

    Write-Output "[1/8] FORWARD  — pin $($pin.Forward), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('FWD', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Forward, 'LOW', 500)
    Start-Sleep -Milliseconds 1000

    Write-Output "[2/8] RIGHT    — pin $($pin.Right), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('RIGHT', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Right, 'LOW', 500)
    Start-Sleep -Milliseconds 1000

    Write-Output "[3/8] FORWARD  — pin $($pin.Forward), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('FWD', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Forward, 'LOW', 500)
    Start-Sleep -Milliseconds 1000

    Write-Output "[4/8] AIM TURRET"
    $d.Clear() | Out-Null
    $d.WriteText('AIM', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    Set-Turret -Pan 45 -Tilt 75
    Start-Sleep -Milliseconds 1200

    Write-Output "[5/8] LASER    — pin $($pin.Laser), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('LASER', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Laser, 'LOW', 500)
    Start-Sleep -Milliseconds 1800

    Write-Output "[6/8] FIRE!    — pin $($pin.MainGun), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('FIRE!', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.MainGun, 'LOW', 500)
    Set-Turret -Pan 45 -Tilt 80   # recoil tilt
    Start-Sleep -Milliseconds 800
    Set-Turret -Pan 45 -Tilt 30   # return
    Start-Sleep -Milliseconds 1200

    Write-Output "[7/8] LEFT     — pin $($pin.Left), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('LEFT', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Left, 'LOW', 500)
    Start-Sleep -Milliseconds 1000

    Write-Output "[8/9] REVERSE  — pin $($pin.Reverse), 500ms"
    $d.Clear() | Out-Null
    $d.WriteText('REVERSE', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    $tank.PulsePin($pin.Reverse, 'LOW', 500)
    Start-Sleep -Milliseconds 1200

    Write-Output "[9/10] STEPPER — slow forward, fast reverse"
    $d.Clear() | Out-Null
    $d.WriteText('STEPPER', 0, 'center', 2, $false) | Out-Null
    Start-Sleep -Milliseconds 800
    Invoke-PsGadgetStepper -PsGadget $stepper -AcBus -DelayMs 10 -Direction Forward -Steps 500 | Out-Null
    Invoke-PsGadgetStepper -PsGadget $stepper -AcBus -DelayMs 1  -Direction Reverse -Steps 500 | Out-Null
    Start-Sleep -Milliseconds 800

    Write-Output "[10/10] STEPPER — fast forward 1024 @ 1ms"
    $d.Clear() | Out-Null
    $d.WriteText('STEPPER', 0, 'center', 2, $false) | Out-Null
    $d.WriteText('GO', 4, 'center') | Out-Null
    Invoke-PsGadgetStepper -PsGadget $stepper -AcBus -DelayMs 1 -Direction Forward -Steps 1024 | Out-Null
    Start-Sleep -Milliseconds 800

    # Outro
    Write-Output "`n[OUTRO]"
    $d.Clear() | Out-Null
    $d.WriteText('DONE', 0, 'center', 2, $false) | Out-Null
    $d.WriteText('thank you', 4, 'center') | Out-Null
    Start-Sleep -Seconds 3
    $d.Clear() | Out-Null

    Write-Output "Demo complete."

} catch {
    Write-Error "Demo failed: $_"
} finally {
    if ($tank)    { $tank.Close() }
    if ($ssd1306) { $ssd1306.Close() }
    if ($turret)  { $turret.Close() }
    if ($stepper) { $stepper.Close() }
    Write-Output "Devices closed."
}
