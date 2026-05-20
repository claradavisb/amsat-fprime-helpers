#!/bin/bash
# Pull and run the AMSAT F Prime ground station from Docker Hub.
#
# Prerequisites:
#   - Docker installed
#   - On WSL2: run "usbipd attach --wsl --busid <BUSID>" first to pass the SDR through
#
# Usage: ./run_hub.sh

set -e

docker pull --platform linux/amd64 claradavis/cubesatsim-fprime-gds:latest

# Open the GDS web interface once it's ready (~15 seconds after start).
(sleep 15 && (cmd.exe /c start http://localhost:5000 2>/dev/null || \
              open http://localhost:5000 2>/dev/null || \
              xdg-open http://localhost:5000 2>/dev/null)) &

docker run --rm -it \
  --platform linux/amd64 \
  --privileged \
  -p 5000:5000 \
  claradavis/cubesatsim-fprime-gds:latest
