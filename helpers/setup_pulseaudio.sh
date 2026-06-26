#!/bin/bash
# PulseAudio null sink to route Direwolf TX into GNU Radio
pactl load-module module-null-sink sink_name=direwolf_tx \
    sink_properties=device.description=direwolf_tx
pactl set-default-source direwolf_tx.monitor

pactl load-module module-null-sink sink_name=direwolf_rx \
    sink_properties=device.description=direwolf_rx
pactl set-default-sink direwolf_rx

# Keep direwolf_tx always RUNNING so its monitor provides a continuous audio
# stream to new_aprs.py. Without this, the monitor goes idle between Direwolf
# frame transmissions and GNU Radio's audio.source stalls, causing HackRF underruns.
pacat --playback --device=direwolf_tx --format=s16le --rate=48000 --channels=1 < /dev/zero &
