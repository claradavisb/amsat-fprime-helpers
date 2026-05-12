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

docker run --rm -it \
  --privileged \
  -p 5000:5000 \
  fprime-groundstation
