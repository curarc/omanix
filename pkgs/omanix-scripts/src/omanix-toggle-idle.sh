#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-idle-inhibited"

refresh_waybar() {
  pkill -RTMIN+9 waybar 2>/dev/null
}

enable_idle() {
  if ! pgrep -x hypridle >/dev/null; then
    hypridle &
  fi
  rm -f "$STATE_FILE"
  refresh_waybar
  [[ -t 0 ]] || notify-send "Idle Inhibit" "Now locking computer when idle"
}

disable_idle() {
  if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
  fi
  hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null
  touch "$STATE_FILE"
  refresh_waybar
  [[ -t 0 ]] || notify-send "Idle Inhibit" "Stop locking computer when idle"
}

show_status() {
  if pgrep -x hypridle >/dev/null; then
    echo "enabled"
    exit 0
  else
    echo "disabled"
    exit 1
  fi
}

case "${1:-}" in
  --status)  show_status ;;
  --enable)  enable_idle ;;
  --disable) disable_idle ;;
  *)
    if pgrep -x hypridle >/dev/null; then
      disable_idle
    else
      enable_idle
    fi
    ;;
esac
