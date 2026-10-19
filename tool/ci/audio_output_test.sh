#!/usr/bin/env bash
# Starts a private PipeWire + pipewire-pulse with two virtual null sinks and
# runs integration_test/audio_reaches_output_test.dart on the Linux desktop
# under Xvfb. The test plays sine WAVs through SoLoud and records the sinks'
# monitors with parec. The script itself also records the monitor of sink A
# for the whole run and fails if nothing ever arrived there.
#
# Needs: pipewire pipewire-pulse wireplumber pulseaudio-utils xvfb (and the
# Linux desktop build tools). Flutter must be on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

WORK="$(mktemp -d)"
export XDG_RUNTIME_DIR="$WORK/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native"
export AUDIO_MONITOR_A=ci_sink_a.monitor
export AUDIO_MONITOR_B=ci_sink_b.monitor
export AUDIO_DEVICE_B_NAME=CiSinkB

pids=()
cleanup() {
  local code=$?
  for pid in "${pids[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  [ "$code" -ne 0 ] && for f in "$WORK"/*.log; do echo "--- $f"; tail -n 40 "$f"; done
  rm -rf "$WORK"
  exit "$code"
}
trap cleanup EXIT

# A session bus is needed by wireplumber (and by pipewire's portal bits).
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] || ! command -v dbus-launch >/dev/null; then
  if command -v dbus-launch >/dev/null; then
    eval "$(dbus-launch --sh-syntax)"
    pids+=("$DBUS_SESSION_BUS_PID")
  fi
fi

pipewire >"$WORK/pipewire.log" 2>&1 & pids+=($!)
for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break; sleep 0.1; done
wireplumber >"$WORK/wireplumber.log" 2>&1 & pids+=($!)
pipewire-pulse >"$WORK/pipewire-pulse.log" 2>&1 & pids+=($!)
for _ in $(seq 100); do pactl info >/dev/null 2>&1 && break; sleep 0.1; done
pactl info >/dev/null || { echo "The sound server did not start" >&2; exit 1; }

pactl load-module module-null-sink sink_name=ci_sink_a \
  sink_properties=device.description=CiSinkA >/dev/null
pactl load-module module-null-sink sink_name=ci_sink_b \
  sink_properties=device.description=CiSinkB >/dev/null
pactl set-default-sink ci_sink_a
echo "Sinks: $(pactl list short sinks | awk '{print $2}' | tr '\n' ' ')"

# Record sink A for the whole run: a second, independent proof that sound
# reached the device (the test makes its own per-phase recordings).
parec -d "$AUDIO_MONITOR_A" --raw --format=s16le --rate=44100 --channels=1 \
  >"$WORK/sink_a.raw" 2>"$WORK/parec.log" & rec=$!
pids+=("$rec")

status=0
xvfb-run -a -s "-screen 0 1280x720x24" \
  flutter test integration_test/audio_reaches_output_test.dart -d linux || status=$?

kill "$rec" 2>/dev/null || true
wait "$rec" 2>/dev/null || true

[ "$status" -eq 0 ] || exit "$status"

# Level of the whole recording (RMS of 16 bit samples, 0..1).
rms=$(python3 - "$WORK/sink_a.raw" <<'PY'
import array, math, sys
a = array.array('h')
data = open(sys.argv[1], 'rb').read()
a.frombytes(data[: len(data) // 2 * 2])
print(math.sqrt(sum(x * x for x in a) / max(len(a), 1)) / 32768)
PY
)
echo "Whole-run RMS on sink A: $rms"
python3 -c "import sys; sys.exit(0 if float('$rms') > 0.02 else 1)" ||
  { echo "Nothing reached the output device" >&2; exit 1; }
echo "Audio reached the output device"
