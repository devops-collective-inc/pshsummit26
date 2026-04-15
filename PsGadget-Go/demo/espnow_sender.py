# espnow_sender.py
# Runs on ESP32 DevKit connected via USB to host PC (/dev/ttyUSB0)
# Listens on UART for BLINK:<sequence> from PowerShell
# Broadcasts the pattern via ESP-NOW to any paired receiver

import network
import espnow
import machine
import time

# UART0 = USB serial on ESP32 DevKit (GPIO1 TX / GPIO3 RX)
uart = machine.UART(0, baudrate=115200)

# ESP-NOW setup — no AP needed, just activate station mode
sta = network.WLAN(network.STA_IF)
sta.active(True)
en = espnow.ESPNow()
en.active(True)

BROADCAST = b'\xff\xff\xff\xff\xff\xff'
en.add_peer(BROADCAST)

led = machine.Pin(2, machine.Pin.OUT)   # onboard LED, GPIO2, active HIGH

print("espnow_sender ready")

while True:
    if uart.any():
        line = uart.readline()
        if line:
            line = line.decode().strip()
            if line.startswith('BLINK:'):
                en.send(BROADCAST, line.encode())
                # Pulse own LED as send confirmation
                led.value(1)
                time.sleep_ms(50)
                led.value(0)
                print("sent:", line)
    time.sleep_ms(10)
