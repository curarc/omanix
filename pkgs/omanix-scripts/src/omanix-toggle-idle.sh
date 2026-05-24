#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-idle-inhibited"

refresh_waybar() {
  pkill -RTMIN+9 waybar 2>/dev/null
}

idle_on() {
  if ! pgrep -x hypridle >/dev/null; then
    hypridle &
  fi
  rm -f "$STATE_FILE"
  refresh_waybar
  [[ -t 0 ]] || notify-send "Idle" "Idle rules enabled"
}

idle_off() {
  if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
  fi
  pkill -f 'omanix-screensaver' 2>/dev/null
  touch "$STATE_FILE"
  refresh_waybar
  [[ -t 0 ]] || notify-send "Idle" "Idle rules disabled"
}

show_status() {
  if pgrep -x hypridle >/dev/null; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status) show_status ;;
  --on)     idle_on ;;
  --off)    idle_off ;;
  *)
    if pgrep -x hypridle >/dev/null; then
      idle_off
    else
      idle_on
    fi
    ;;
esac
