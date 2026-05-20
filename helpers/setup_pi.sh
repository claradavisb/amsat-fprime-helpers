#!/bin/bash
# One-time setup script to configure the CubeSatSim Pi for F Prime operation.
# Run once on the Pi: bash setup_pi.sh
# Or remotely: ssh pi@<PI_IP> 'bash -s' < setup_pi.sh
#
# Before running, copy the F Prime flight binary to the Pi:
#   scp -r build-artifacts/arm-hf-linux/CDHDeployment pi@<PI_IP>:/home/pi/CDHDeployment

set -e

# initializes the FM radio module
sudo systemctl enable cubesatsim.service

rm -f /home/pi/CubeSatSim/command_control
echo "CubeSatSim command and control disabled"

# Receives the HackRF uplink and passes frames to F Prime over KISS TCP
sudo tee /etc/systemd/system/direwolf-fprime.service > /dev/null << 'EOF'
[Unit]
Description=Direwolf APRS receiver (F Prime uplink)
After=sound.target

[Service]
ExecStart=/usr/bin/direwolf -c /home/pi/direwolf-pi.conf
Restart=on-failure
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable direwolf-fprime.service

# Starts the CDHDeployment binary on boot. Waits for Direwolf to open the port
sudo tee /etc/systemd/system/fprime-flight.service > /dev/null << 'EOF'
[Unit]
Description=F Prime CDH flight software
After=network.target direwolf-fprime.service
Wants=direwolf-fprime.service

[Service]
ExecStart=/home/pi/CDHDeployment/bin/CDHDeployment
WorkingDirectory=/home/pi/CDHDeployment
Restart=on-failure
User=pi

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable fprime-flight.service

echo ""
echo "Pi setup complete."
echo "Reboot the Pi to start all services on boot."
