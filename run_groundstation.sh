#!/bin/bash
# Build and run the AMSAT F Prime ground station container.
# Everything (repos, ARM build, GDS plugin) is set up inside the image.
#
# Prerequisites:
#   - Docker installed
#   - On WSL2: run "usbipd attach --wsl --busid <BUSID>" first to pass the SDR through
#
# Usage: ./run_groundstation.sh

set -e

docker build -f Dockerfile.groundstation -t fprime-groundstation .

echo ""
echo "Ground station container ready."
echo "Inside the container (working dir is /opt/amsat-fprime-helpers/helpers):"
echo "  ./setup_pulseaudio.sh"
echo "  direwolf -c direwolf-tx.conf"
echo "  python3 new_aprs.py"
echo "  . /opt/fprime-venv/bin/activate && fprime-gds --communication-selection ip \\"
echo "      --ip-address 127.0.0.1 --ip-port 8001 --ip-client \\"
echo "      --framing-selection ax25-kiss \\"
echo "      -d /opt/fprime-amsat-reference/build-artifacts/arm-hf-linux/CDHDeployment -n"
echo ""
echo "The built ARM binary is at:"
echo "  /opt/fprime-amsat-reference/build-artifacts/arm-hf-linux/CDHDeployment/bin/CDHDeployment"
echo ""

docker run --rm -it \
  --privileged \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /run/user/0/pulse:/run/user/0/pulse \
  -e PULSE_SERVER=unix:/run/user/0/pulse/native \
  fprime-groundstation
