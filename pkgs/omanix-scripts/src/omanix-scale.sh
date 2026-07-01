#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

refresh_waybar() {
  # Full config/style reload, not RTMIN+9 (which only refreshes a single
  # custom module's icon) — barHeight/fontSize are structural changes.
  pkill -SIGUSR2 waybar 2>/dev/null
}

scale_on() {
  ln -sf "$WAYBAR_DIR/config-2x.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-2x.css" "$WAYBAR_DIR/style.css"
  refresh_waybar
  touch "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI enabled"
}

scale_off() {
  ln -sf "$WAYBAR_DIR/config-1x.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-1x.css" "$WAYBAR_DIR/style.css"
  refresh_waybar
  rm -f "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI disabled"
}

show_status() {
  if [[ -f "$STATE_FILE" ]]; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status) show_status ;;
  --on)     scale_on ;;
  --off)    scale_off ;;
  *)
    if [[ -f "$STATE_FILE" ]]; then
      scale_off
    else
      scale_on
    fi
    ;;
esac
