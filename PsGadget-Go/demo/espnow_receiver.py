

# espnow_receiver.py
# Runs on remote ESP32 (untethered, battery or USB power)
# Listens for ESP-NOW BLINK packets and replays the pattern on the onboard LED

import network
import espnow
import machine
import time

sta = network.WLAN(network.STA_IF)
sta.active(True)
en = espnow.ESPNow()
en.active(True)

BROADCAST = b'\xff\xff\xff\xff\xff\xff'
en.add_peer(BROADCAST)

led = machine.Pin(2, machine.Pin.OUT)   # onboard LED, GPIO2, active HIGH

print("espnow_receiver ready")


def blink_pattern(seq):
    on = True
    for ms in seq:
        led.value(1 if on else 0)
        time.sleep_ms(int(ms))
        on = not on
    led.value(0)


while True:
    peer, msg = en.recv(timeout_ms=100)
    if msg:
        msg = msg.decode().strip()
        if msg.startswith('BLINK:'):
            seq = msg[6:].split(',')
            print("blink:", seq)
            blink_pattern(seq)
