# espnow_controller.py
# Runs on ESP32 wired sender (ttyUSB1 via FT232RNL, UART0 GPIO1/GPIO3)
# Discovers ESP-NOW peripherals and relays BLINK commands from PowerShell
#
# Uses sys.stdin + select.poll() instead of machine.UART(0) so the REPL
# and Ctrl+C remain active — mpremote can always interrupt after a reset.
#
# LED states:
#   OFF              = searching / no peers paired
#   Single flash     = peer just paired
#   Pattern replay   = BLINK command forwarded
#
# Deploy:
#   mpremote connect /dev/ttyUSB1 fs cp espnow_controller.py :main.py + reset

import sys, select, network, espnow, ubinascii, time
from machine import Pin

CTSSID    = "PSGADGET-CTRL"
BROADCAST = b'\xFF\xFF\xFF\xFF\xFF\xFF'

wlan = network.WLAN(network.STA_IF)
wlan.active(True)

en = espnow.ESPNow()
en.active(True)
en.add_peer(BROADCAST)

_led = Pin(2, Pin.OUT)
_led.value(0)

def led_on():  _led.value(1)
def led_off(): _led.value(0)

# Poll sys.stdin (UART0) without reinitializing it — keeps REPL + Ctrl+C alive
poll = select.poll()
poll.register(sys.stdin, select.POLLIN)

peers = []
_msg_ready = [False]

def _irq(_): _msg_ready[0] = True
en.irq(_irq)

MY_MAC = ubinascii.hexlify(wlan.config("mac"), ":").decode()
print("CTRL mac={}".format(MY_MAC))
print("Waiting for peers...")

# Drain stale UART0 buffer — wait for 500ms of silence before proceeding
_drain_quiet = time.ticks_ms()
while time.ticks_diff(time.ticks_ms(), _drain_quiet) < 500:
    if poll.poll(0):
        sys.stdin.read(1)
        _drain_quiet = time.ticks_ms()  # reset silence timer on each byte
    time.sleep_ms(10)

last_beacon = 0
buf = ""

while True:
    now = time.ticks_ms()

    # Broadcast discovery beacon every 500 ms
    if time.ticks_diff(now, last_beacon) >= 500:
        en.send(BROADCAST, CTSSID.encode())
        last_beacon = now

    # Handle incoming ESP-NOW (HELLO responses from peripherals)
    if _msg_ready[0]:
        _msg_ready[0] = False
        try:
            mac, data = en.recv()
            if mac and data:
                msg = data.decode()
                if msg.startswith("HELLO:") and mac not in peers:
                    try:
                        en.add_peer(mac)
                    except Exception:
                        pass
                    peers.append(mac)
                    print("Paired:", ubinascii.hexlify(mac, ":").decode())
                    led_on(); time.sleep_ms(200); led_off()
        except Exception as e:
            print("recv err:", e)

    # Handle BLINK commands from PowerShell over UART0 (non-blocking)
    if poll.poll(0):
        ch = sys.stdin.read(1)
        if ch in ('\r', '\n'):
            cmd = buf.strip()
            buf = ""
            if cmd.startswith("BLINK:"):
                try:
                    seq = [int(x) for x in cmd[6:].split(",")]
                    assert seq and all(20 <= d <= 5000 for d in seq)
                except Exception:
                    buf = ""; continue
                print("fwd:", cmd)
                targets = peers if peers else [BROADCAST]
                for mac in targets:
                    en.send(mac, cmd.encode())
                # Replay pattern locally as visual confirmation
                for dur in seq:
                    led_on();  time.sleep_ms(dur)
                    led_off(); time.sleep_ms(100)
        else:
            buf += ch

    time.sleep_ms(10)
