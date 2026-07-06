#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active"
OTHER_MONITORS_STATE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-other-monitors"
DUMMY_STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-dummy-display-active"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

# Settle delay between monitor-state hyprctl calls in the dummy-display
# orchestration below. NOT a Nix-tunable option — this is purely an
# implementation detail to avoid the stall described in wait_for_monitor_state.
DUMMY_SETTLE_SECONDS=1.5

refresh_waybar() {
  # Full config/style reload, not RTMIN+9 (which only refreshes a single
  # custom module's icon) — barHeight/fontSize are structural changes.
  pkill -SIGUSR2 waybar 2>/dev/null
}

# Waybar/walker/foot's sizing tables assume a specific compositor scale (see
# waybar.nix's mkBarHeight/mkFontSize: "1" -> normal size, anything else ->
# the 2x-tuned variant). Shared by both scaledDesktop (scale_on/off) and
# dummyDisplay (dummy_display_on/off) so the two toggles can never disagree
# about which variant is correct for a given scale value.
apply_waybar_variant() {
  local scale="$1" variant
  variant="2x"
  [[ "$scale" == "1" ]] && variant="1x"
  ln -sf "$WAYBAR_DIR/config-${variant}.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-${variant}.css" "$WAYBAR_DIR/style.css"
  refresh_waybar
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

# Moonlight maps the client's pointer motion onto the streamed monitor's
# logical (post-scale) resolution, so doubling the monitor scale above makes
# the same physical trackpad/mouse movement feel much faster, and the cursor
# bitmap (rendered at a fixed nominal size times the scale factor) grows
# right along with everything else. Both are purely cosmetic/feel issues
# introduced by scaling, so they're corrected here in lockstep with it.
set_pointer_feel() {
  local sensitivity="$1" cursor_size="$2"
  [[ -n "$sensitivity" ]] && hyprctl eval "hl.config({ input = { sensitivity = $sensitivity } })"
  [[ -n "$cursor_size" ]] && hyprctl setcursor "${HYPRCURSOR_THEME:-Adwaita}" "$cursor_size"
}

# Any other connected monitor (a second local display, not the one Sunshine
# streams) has no static mode/position declared anywhere — unlike
# OMANIX_SCALE_MONITOR, it's not configured via omanix.sunshine.scaledDesktop.
# So its current mode/position/scale is read live from Hyprland and
# snapshotted to OTHER_MONITORS_STATE before scaling it up, letting scale_off
# restore the exact prior values instead of guessing a revert factor.
scale_other_monitors_on() {
  : > "$OTHER_MONITORS_STATE"
  hyprctl monitors -j | jq -c '.[] | select(.disabled == false)' | while read -r mon; do
    name=$(jq -r '.name' <<<"$mon")
    [[ "$name" == "$OMANIX_SCALE_MONITOR" ]] && continue
    mode=$(jq -r '"\(.width)x\(.height)@\((.refreshRate * 100 | round) / 100)"' <<<"$mon")
    position=$(jq -r '"\(.x)x\(.y)"' <<<"$mon")
    scale=$(jq -r '.scale' <<<"$mon")
    echo "$name|$mode|$position|$scale" >>"$OTHER_MONITORS_STATE"
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$1' })"
  done
}

scale_other_monitors_off() {
  [[ -f "$OTHER_MONITORS_STATE" ]] || return 0
  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    # Skip monitors that were unplugged since scale_other_monitors_on ran.
    hyprctl monitors -j | jq -e --arg n "$name" '.[] | select(.name == $n and .disabled == false)' >/dev/null 2>&1 || continue
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$scale' })"
  done <"$OTHER_MONITORS_STATE"
  rm -f "$OTHER_MONITORS_STATE"
}

scale_on() {
  set_monitor_scale "$OMANIX_SCALE_FACTOR"
  scale_other_monitors_on "$OMANIX_SCALE_FACTOR"
  set_pointer_feel "$OMANIX_SCALE_SENSITIVITY" "$OMANIX_SCALE_CURSOR_SIZE"
  apply_waybar_variant "$OMANIX_SCALE_FACTOR"
  touch "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI enabled"
}

scale_off() {
  set_monitor_scale "$OMANIX_SCALE_REVERT_FACTOR"
  scale_other_monitors_off
  set_pointer_feel "$OMANIX_SCALE_REVERT_SENSITIVITY" "$OMANIX_SCALE_REVERT_CURSOR_SIZE"
  apply_waybar_variant "$OMANIX_SCALE_REVERT_FACTOR"
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

# Polls `hyprctl monitors -j` for a monitor named "$1" to reach enabled-state
# "$2" (true/false) within a few seconds. Twice during development, chaining
# `hyprctl eval hl.monitor(...)` calls back-to-back (in particular, ever
# passing through a moment where ZERO monitors were enabled) put Hyprland's
# DRM/render thread into a state where hyprctl's IPC kept replying "ok" to
# every command while nothing was actually changing on screen — both real
# monitors went black and stayed that way until recovery. `hyprctl reload`
# (NOT a full Hyprland restart) reliably un-stuck it within ~1s both times.
# This defensive check exists so that failure mode self-heals instead of
# requiring a human to notice and intervene.
wait_for_monitor_state() {
  local name="$1" want_enabled="$2" tries=0
  while (( tries < 4 )); do
    local disabled
    disabled=$(hyprctl monitors -j | jq -r --arg n "$name" '.[] | select(.name == $n) | .disabled')
    if [[ "$want_enabled" == "true" && "$disabled" == "false" ]]; then
      return 0
    elif [[ "$want_enabled" == "false" && ( -z "$disabled" || "$disabled" == "true" ) ]]; then
      return 0
    fi
    sleep 0.5
    (( tries++ ))
  done
  notify-send "Dummy Display" "Monitor state didn't apply as expected, recovering..." 2>/dev/null
  hyprctl reload
  sleep 1
}

# Orchestrates which monitors are enabled so Sunshine's Wayland capture has
# exactly one candidate output (the dummy plug) to auto-select — no
# `output_name` override needed, confirmed Sunshine picks whichever monitor
# is the sole enabled one.
#
# ORDERING IS SAFETY-CRITICAL, do not "simplify" into fewer/batched calls:
#   connect:    enable dummy FIRST, then disable real monitors one at a time
#   disconnect: enable real monitors one at a time FIRST, then disable dummy
# At every step, at least one monitor must remain enabled. Going through a
# moment with zero enabled monitors is exactly what triggered the DRM stall
# above during testing. A settle delay between EVERY hyprctl eval call is
# also required — the stall was also observed when calls were fired without
# one, even when never reaching zero enabled monitors.
#
# Real monitors normally use Hyprland's "auto" position (see
# omanix.monitors.position) — but "auto" re-flows EVERY auto-positioned
# monitor whenever any monitor's enabled state changes, so enabling/disabling
# the dummy plug would otherwise silently shift your real monitors to new
# positions. This is why OMANIX_DUMMY_DISPLAY_REAL_MONITORS carries each real
# monitor's exact mode/position/scale: every hyprctl eval call below sets them
# explicitly, so "auto" is never in play for any monitor this script touches.
#
# apply_waybar_variant below is called with the dummy connector's OWN scale
# on connect (that's what's actually rendered on the streamed monitor,
# unlike scaledDesktop where a single real monitor is both scaled and
# rendered), and with the real monitors' scale on disconnect.
dummy_display_on() {
  [[ -n "$OMANIX_DUMMY_DISPLAY_CONNECTOR" ]] || return 0

  hyprctl eval "hl.monitor({ output = '$OMANIX_DUMMY_DISPLAY_CONNECTOR', mode = '$OMANIX_DUMMY_DISPLAY_MODE', position = '$OMANIX_DUMMY_DISPLAY_POSITION', scale = '$OMANIX_DUMMY_DISPLAY_SCALE', disabled = false })"
  wait_for_monitor_state "$OMANIX_DUMMY_DISPLAY_CONNECTOR" true
  sleep "$DUMMY_SETTLE_SECONDS"

  set_pointer_feel "$OMANIX_DUMMY_DISPLAY_SENSITIVITY" "$OMANIX_DUMMY_DISPLAY_CURSOR_SIZE"
  apply_waybar_variant "$OMANIX_DUMMY_DISPLAY_SCALE"

  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    hyprctl eval "hl.monitor({ output = '$name', disabled = true })"
    wait_for_monitor_state "$name" false
    sleep "$DUMMY_SETTLE_SECONDS"
  done <<< "$OMANIX_DUMMY_DISPLAY_REAL_MONITORS"

  touch "$DUMMY_STATE_FILE"
  [[ -t 0 ]] || notify-send "Dummy Display" "Streaming display enabled"
}

# OMANIX_DUMMY_DISPLAY_REAL_MONITORS is a static list baked in by the Nix
# wrapper (from omanix.sunshine.dummyDisplay.realMonitors), identical on
# every invocation — unlike scale_other_monitors_on/off's snapshot, which
# captures genuinely dynamic state discovered at runtime, there's nothing to
# snapshot here: the real monitors' normal mode/position/scale are already
# fully known ahead of time, so --dummy-off can restore them directly from
# the env var with no state file to go stale or go missing.
dummy_display_off() {
  [[ -n "$OMANIX_DUMMY_DISPLAY_CONNECTOR" ]] || return 0

  local first_real_scale=""
  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    [[ -z "$first_real_scale" ]] && first_real_scale="$scale"
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$scale', disabled = false })"
    wait_for_monitor_state "$name" true
    sleep "$DUMMY_SETTLE_SECONDS"
  done <<< "$OMANIX_DUMMY_DISPLAY_REAL_MONITORS"

  set_pointer_feel "$OMANIX_DUMMY_DISPLAY_REVERT_SENSITIVITY" "$OMANIX_DUMMY_DISPLAY_REVERT_CURSOR_SIZE"
  # Real monitors' own scale (just restored above) drives which waybar
  # variant is correct locally — not a hardcoded "1x", since a host could
  # run its real monitors scaled too. All real monitors normally share the
  # same local desktop scale, so the first one's value is representative.
  apply_waybar_variant "$first_real_scale"

  hyprctl eval "hl.monitor({ output = '$OMANIX_DUMMY_DISPLAY_CONNECTOR', disabled = true })"
  wait_for_monitor_state "$OMANIX_DUMMY_DISPLAY_CONNECTOR" false

  rm -f "$DUMMY_STATE_FILE"
  [[ -t 0 ]] || notify-send "Dummy Display" "Streaming display disabled"
}

show_dummy_status() {
  if [[ -f "$DUMMY_STATE_FILE" ]]; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status)      show_status ;;
  --on)          scale_on ;;
  --off)         scale_off ;;
  --dummy-status) show_dummy_status ;;
  --dummy-on)    dummy_display_on ;;
  --dummy-off)   dummy_display_off ;;
  *)
    if [[ -f "$STATE_FILE" ]]; then
      scale_off
    else
      scale_on
    fi
    ;;
esac
