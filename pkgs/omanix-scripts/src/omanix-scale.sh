#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

refresh_waybar() {
  # Full config/style reload, not RTMIN+9 (which only refreshes a single
  # custom module's icon) — barHeight/fontSize are structural changes.
  pkill -SIGUSR2 waybar 2>/dev/null
}

set_monitor_scale() {
  # Only meaningful when omanix.sunshine.scaledDesktop is configured (the
  # env vars are injected from osConfig — see
  # modules/home-manager/scripts/default.nix). Sunshine's own prep-cmd used
  # to run this hyprctl command separately from omanix-scale, which let the
  # two drift apart: triggering omanix-scale from the menu changed
  # waybar/walker/foot's sizing tables (which assume a 2x compositor scale)
  # WITHOUT changing the compositor scale itself, making the UI shrink
  # instead of grow. Owning both here in one place means the menu toggle and
  # the Sunshine prep-cmd can never disagree again.
  [[ -n "$OMANIX_SCALE_MONITOR" ]] || return 0
  hyprctl eval "hl.monitor({ output = '$OMANIX_SCALE_MONITOR', mode = '$OMANIX_SCALE_MODE', position = '$OMANIX_SCALE_POSITION', scale = '$1' })"
}

scale_on() {
  set_monitor_scale "$OMANIX_SCALE_FACTOR"
  ln -sf "$WAYBAR_DIR/config-2x.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-2x.css" "$WAYBAR_DIR/style.css"
  refresh_waybar
  touch "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI enabled"
}

scale_off() {
  set_monitor_scale "$OMANIX_SCALE_REVERT_FACTOR"
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
