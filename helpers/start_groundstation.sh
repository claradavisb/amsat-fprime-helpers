#!/bin/bash
# Starts all ground station components in a tmux session with labelled panes.
# Layout:
#   +-------------------------+-------------------------+
#   | [direwolf]              | [hackrf / new_aprs.py]  |
#   +-------------------------+-------------------------+
#   | [fprime-gds]            | [shell]                 |
#   +-------------------------+-------------------------+

SESSION="groundstation"
GDS_DICT="/opt/fprime-amsat-reference/build-artifacts/arm-hf-linux/CDHDeployment"
VENV=". /opt/fprime-venv/bin/activate"

# Configure PulseAudio to accept anonymous connections
cat > /etc/pulse/system.pa << 'EOF'
load-module module-native-protocol-unix auth-anonymous=1
load-module module-always-sink
EOF

# Point all clients at the system socket
cat > /etc/pulse/client.conf << 'EOF'
default-server = unix:/var/run/pulse/native
autospawn = no
enable-shm = false
EOF

mkdir -p /var/run/pulse
pulseaudio -D --system || true
sleep 2
./setup_pulseaudio.sh

tmux new-session -d -s $SESSION -x 220 -y 50
tmux set -g mouse on
# Run GNU Radio headless (no X11 needed)
tmux setenv -g QT_QPA_PLATFORM offscreen
sleep 1

# Pane 0 (top left): Direwolf
PANE0=$SESSION:0.0
tmux send-keys -t $PANE0 'direwolf -c direwolf-tx.conf' Enter

# Pane 1 (top right): GNU Radio + HackRF
PANE1=$(tmux split-window -h -t $PANE0 -P -F "#{pane_id}")
sleep 0.5
tmux send-keys -t $PANE1 'python3 new_aprs.py' Enter

# Pane 2 (bottom left): fprime-gds
PANE2=$(tmux split-window -v -t $PANE0 -P -F "#{pane_id}")
sleep 0.5
tmux send-keys -t $PANE2 \
  "$VENV && fprime-gds --communication-selection ip --ip-address 127.0.0.1 --ip-port 8001 --ip-client --framing-selection ax25-kiss -d $GDS_DICT --gui-addr 0.0.0.0 -n" Enter

# Pane 3 (bottom right): spare shell
tmux split-window -v -t $PANE1
sleep 0.5

# Attach if running in a terminal; otherwise keep the container alive so the
# GDS web interface remains reachable from Docker Desktop / docker run -d.
tmux attach-session -t $SESSION 2>/dev/null || tail -f /dev/null
