function Start-FusionDemo {
<#
    Final demo: WMI + FileSystemWatcher + Timer running concurrently.
    Safe to re-run; cleans prior subscriptions and objects.
#>

    # --- Clean slate ---
    Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
    Get-Event | Remove-Event -ErrorAction SilentlyContinue

    # --- 1) WMI/CIM: Process Start ---
    Register-CimIndicationEvent -ClassName Win32_ProcessStartTrace -SourceIdentifier ProcStart -Action {
        Write-Host "Process started: $($Event.SourceEventArgs.NewEvent.ProcessName)" -ForegroundColor Yellow
    } | Out-Null


    # --- 2) FileSystemWatcher: File Events ---
    $global:FusionFolder = Join-Path $env:TEMP 'FusionDemo'
    New-Item -ItemType Directory -Force -Path $global:FusionFolder | Out-Null

    $global:fsw = New-Object System.IO.FileSystemWatcher $global:FusionFolder, '*'
    $global:fsw.IncludeSubdirectories = $false
    $global:fsw.EnableRaisingEvents   = $true

    Register-ObjectEvent $global:fsw Created -SourceIdentifier Fusion_FileCreated -Action {
        Write-Host "📄 FILE CREATED: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Green
    } | Out-Null

    # --- 3) Timer: Heartbeat ---
    $global:timer = New-Object System.Timers.Timer 2000
    $global:timer.AutoReset = $true
    $global:timer.Enabled   = $true

    Register-ObjectEvent -InputObject $global:timer -EventName Elapsed -SourceIdentifier Fusion_Timer -Action {
        Write-Host "                                  ⏱️ TIMER TICK: $(Get-Date -Format HH:mm:ss)" -ForegroundColor DarkYellow
    } | Out-Null

    Write-Host "`n🔥 Fusion Demo is LIVE!" -ForegroundColor Green
    Write-Host "Try these:" -ForegroundColor DarkGray
    Write-Host "  notepad.exe"
    Write-Host "  New-Item $env:TEMP\FusionDemo\a.txt"
    Write-Host "  Wait ~2 seconds for timer ticks"
}
