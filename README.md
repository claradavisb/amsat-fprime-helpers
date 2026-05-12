# AMSAT F Prime Ground Station

Docker-based ground station that bridges F Prime GDS to a CubeSatSim over a 435 MHz FM uplink using a HackRF SDR.

## Prerequisites

- Docker (with USB device passthrough support)
- HackRF One connected via USB
- CubeSatSim

## Setup and Installation

Run:

```bash
./run_groundstation.sh
```

This passes through the HackRF USB device and starts a tmux session with four panes:

| Top left | Top right |
|---|---|
| Direwolf (TX) | GNU Radio / HackRF |
| **Bottom left** | **Bottom right** |
| F Prime GDS | Shell |

The GDS web interface is available at `http://localhost:5000`.

### CubeSatSim setup

Ensure `transmit.service` is running on the Pi. It initializes the radio module and without it will not receive the HackRF signal.

```bash
# On the Pi
sudo systemctl status transmit.service
sudo systemctl enable --now transmit.service
```

`command.service` should be disabled as it now replaced with the F Prime GDS

```bash
sudo systemctl disable --now command.service
```

## Usage

1. Start the container with `./run_groundstation.sh`
2. Wait for the container to initialize
3. Open `http://localhost:5000` in a browser
4. Navigate to Commanding and send a command (e.g. `cmdDisp.CMD_NO_OP`)
5. Verify the Pi's Direwolf shows decoded frames

## Troubleshooting

### HackRF gain / audio level

The HackRF TX chain in `new_aprs.py` is set to `gain=14` (RF amp on), `if_gain=20`. At bench distance (HackRF next to CubeSatSim) the Pi Direwolf audio level will be above the recommended 50 — this is expected and frames still decode correctly. Moving the HackRF antenna a few feet away from the CubeSatSim will bring the level closer to optimal.

### No signal on Pi / frames not decoding

1. Confirm `transmit.service` is running on the Pi
2. Confirm the HackRF TX light is on
3. Check PulseAudio routing: inside the container run `pactl list sink-inputs short` — Direwolf should appear as a sink input, and `pactl list source-outputs short` should show new_aprs.py reading from `direwolf_tx.monitor`

### USB sound card device number changed (Pi)

If `arecord -l` shows the sound card at a different index than expected, update `direwolf-pi.conf` on the Pi:

```
ADEVICE plughw:X,0   # replace X with the card number
```
