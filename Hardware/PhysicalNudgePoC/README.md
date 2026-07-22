# Physical Nudge PoC — Wiring

Fun demo hardware for a launch video: when the Mac app detects sustained
poor posture, it POSTs to this board over LAN, which swings a servo and
flashes a fist icon on the onboard LED matrix. Not part of the shipped app.

## Bill of materials

- Arduino UNO R4 WiFi
- SG90 micro servo (9g)
- External 5V power supply for the servo (bench supply, powered USB hub,
  or a separate 5V wall adapter — anything that isn't the Uno's own
  5V/USB rail)
- Jumper wires

## Wiring

| SG90 wire         | Connects to                              |
|--------------------|-------------------------------------------|
| orange (signal)    | Arduino UNO R4 WiFi, pin **D9**            |
| red (power)        | External 5V supply, **+5V**                |
| brown (ground)     | Common ground rail                         |

**Common ground rail** — these three must all be tied together at one
point, or the signal reference floats and the servo jitters/won't respond:
- Arduino UNO R4 WiFi **GND** pin
- Servo **brown** wire
- External 5V supply **GND** terminal

```
   SG90 servo                 Arduino UNO R4 WiFi
  ┌───────────┐               ┌─────────────────────┐
  │ orange ───┼───────────────┤ D9                   │
  │ (signal)  │               │                      │
  │           │               │ GND ─────────┐       │
  │ brown  ───┼───────────────┤ (also here)  │       │
  │ (GND)     │               └──────────────┼───────┘
  │           │                              │
  │ red    ───┼──────────────┐               │
  │ (power)   │              │               │
  └───────────┘         ┌────▼────┐    ┌─────▼─────┐
                         │  +5V    │    │    GND    │
                         │  External 5V supply       │
                         └────────────────────────────┘
```

> ⚠️ **Do not power the servo from the Uno's own 5V or USB pin.** The
> SG90's stall current can brown out the board mid-swing - this is what
> caused reliability issues on an earlier revision of this PoC. Always
> use a separate 5V source, tied to the same ground.

## Onboard LED matrix

No wiring required — the UNO R4 WiFi's built-in 12x8 LED matrix is
driven directly from the sketch via the bundled `Arduino_LED_Matrix`
library. On every `/nudge` call it flashes a fist/punch icon in sync
with the servo swing, then clears.

## Board setup (Arduino IDE)

1. Tools → Board → Boards Manager → install **"Arduino UNO R4 Boards"**
2. Tools → Board → select **"Arduino UNO R4 WiFi"**, and the correct port
3. No extra library installs needed — `Servo.h`, `WiFiS3.h`, and
   `Arduino_LED_Matrix.h` all ship with the core
4. Flash `PhysicalNudgePoC.ino`

## Verifying

1. Open Serial Monitor at **115200 baud** — it prints `Connecting to
   WiFi....` then the board's IP address once connected
   - If it hangs on the dots, update the WiFi co-processor firmware via
     **File → Examples → WiFiS3 → Tools → FirmwareUpdater**
2. Bench test: `curl -X POST http://<uno-ip>/nudge` — servo should swing
   to 90° and back, LED matrix should flash the fist icon
3. In the Mac app, set **Settings → hardwareNudgeIP** to the board's IP
   and enable **hardwareNudgeEnabled** — no app-side code changes needed,
   `HardwareTriggerManager` just POSTs to whatever IP is configured
