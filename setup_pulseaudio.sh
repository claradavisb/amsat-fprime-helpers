#!/bin/bash
# PulseAudio null sink to route Direwolf TX into GNU Radio
pactl load-module module-null-sink sink_name=direwolf_tx \
    sink_properties=device.description=direwolf_tx
pactl set-default-source direwolf_tx.monitor
