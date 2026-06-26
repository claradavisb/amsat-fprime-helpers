#!/bin/bash
# Run once on the Pi: bash setup_pi.sh
# Or remotely: ssh pi@<PI_IP> 'bash -s' < setup_pi.sh
#
# Before running, copy the F Prime flight binary to the Pi:
#   scp -r build-artifacts/arm-hf-linux/CDHDeployment pi@<PI_IP>:/home/pi/CDHDeployment

set -e

# Disable CubeSatSim — F Prime replaces its functionality.
# CubeSatSim directly manages GPIO 20 (SR105U PTT) which prevents uplink RX.
sudo systemctl disable cubesatsim.service
sudo systemctl stop cubesatsim.service || true
echo "CubeSatSim disabled"

# Disable the push button listener — it monitors GPIO 26 and causes reboots
# when rpitx generates noise on nearby GPIO lines.
sudo systemctl disable listen-for-shutdown.service
sudo systemctl stop listen-for-shutdown.service || true
echo "listen-for-shutdown disabled"


# Receives the HackRF uplink and passes frames to F Prime over KISS TCP
sudo tee /etc/systemd/system/direwolf-fprime.service > /dev/null << 'EOF'
[Unit]
Description=Direwolf APRS receiver (F Prime uplink)
After=sound.target

[Service]
ExecStart=/usr/local/bin/direwolf -c /home/pi/direwolf-pi.conf
Restart=on-failure
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable direwolf-fprime.service

# Direwolf config: receive-only on 435 MHz via USB sound card.
# No PTT — downlink TX is handled by rpitx in F Prime RadioBridge.
sudo tee /home/pi/direwolf-pi.conf > /dev/null << 'EOF'
ADEVICE  plughw:1,0
ARATE    48000
CHANNEL  0
MYCALL   N0CALL-0
MODEM    1200
KISSPORT 8001
EOF

# Starts the CDHDeployment binary on boot.
# Waits for network (so rpitx doesn't jam WiFi) and Direwolf (for KISS port).
sudo tee /etc/systemd/system/fprime-flight.service > /dev/null << 'EOF'
[Unit]
Description=F Prime CDH flight software
After=network.target direwolf-fprime.service
Wants=direwolf-fprime.service

[Service]
ExecStart=/home/pi/CDHDeployment -a 0.0.0.0 -p 50000
WorkingDirectory=/home/pi
Restart=on-failure
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable fprime-flight.service

# Initialize the SR105U FM transceiver on boot:
#   - Power up the module (GPIO 21)
#   - Hold PTT HIGH (GPIO 20) so the module stays in receive mode
#   - Program RX=435.0 MHz, TX=434.9 MHz, squelch=0 (open) via serial
# rpitx drives GPIO 4 directly for downlink TX and does not use GPIO 20.
sudo tee /home/pi/fm_init.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import RPi.GPIO as GPIO
from time import sleep
import serial

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(21, GPIO.OUT)  # pd
GPIO.setup(20, GPIO.OUT)  # ptt
GPIO.output(21, 1)        # power up
GPIO.output(20, 1)        # receive mode (PTT high = RX)

try:
    ser = serial.Serial("/dev/ttyAMA0", 9600)
    cmd = b"AT+DMOSETGROUP=0,435.0000,434.9000,0,0,0,0\r\n"
    for _ in range(6):
        ser.write(cmd)
        sleep(0.1)
    ser.close()
    print("FM module programmed: RX=435.0 MHz TX=434.9 MHz")
except Exception as e:
    print(f"FM init error: {e}")
EOF
sudo chmod +x /home/pi/fm_init.py

# Run fm_init as a one-shot service on boot so the SR105U is ready before
# Direwolf and F Prime start.
sudo tee /etc/systemd/system/fm-init.service > /dev/null << 'EOF'
[Unit]
Description=SR105U FM module init
After=basic.target
Before=direwolf-fprime.service fprime-flight.service

[Service]
ExecStart=python3 -u /home/pi/fm_init.py
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable fm-init.service

echo ""
echo "Pi setup complete."
echo "Reboot the Pi to start all services on boot."
