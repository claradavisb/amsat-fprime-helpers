#!/bin/bash
# Starts all ground station components in a tmux session with labelled panes.
# Layout:
#   +-------------------------+-------------------------+
#   | [direwolf]              | [hackrf / new_aprs.py]  |
#   +-------------------------+-------------------------+
#   | [fprime-gds]            | [shell]                 |
#   +-------------------------+-------------------------+

set -e

SESSION="groundstation"
GDS_DICT="/opt/fprime-amsat-reference/build-artifacts/arm-hf-linux/CDHDeployment"
VENV=". /opt/fprime-venv/bin/activate"

# Set up PulseAudio null sink
pulseaudio --start
sleep 1
./setup_pulseaudio.sh

tmux new-session -d -s $SESSION -x 220 -y 50

# Pane 0: Direwolf
tmux send-keys -t $SESSION:0 'direwolf -c direwolf-tx.conf' Enter

# Pane 1: GNU Radio + HackRF
tmux split-window -h -t $SESSION:0
tmux send-keys -t $SESSION:0.1 'python3 new_aprs.py' Enter

# Pane 2: fprime-gds
tmux split-window -v -t $SESSION:0.0
tmux send-keys -t $SESSION:0.2 \
  "$VENV && fprime-gds --communication-selection ip --ip-address 127.0.0.1 --ip-port 8001 --ip-client --framing-selection ax25-kiss -d $GDS_DICT --gui-addr 0.0.0.0 -n" Enter

# Pane 3: spare shell
tmux split-window -v -t $SESSION:0.1

tmux attach-session -t $SESSION
