#!/usr/bin/env bash
# omanix-smart-delete: Smart delete line based on window class
# Injects appropriate shortcut for terminal vs GUI applications

# 1. Get info about the currently active window
ACTIVE=$(hyprctl activewindow -j)
CLASS=$(echo "$ACTIVE" | jq -r ".class")
ADDRESS=$(echo "$ACTIVE" | jq -r ".address")

# Target specific window by address to ensure focus doesn't drift
TARGET="address:$ADDRESS"

# 2. Check if it's a terminal
if [[ "$CLASS" =~ "ghostty" || "$CLASS" =~ "foot" || "$CLASS" =~ "kitty" || "$CLASS" =~ "Alacritty" || "$CLASS" =~ "neovide" ]]; then
  hyprctl dispatch "hl.dsp.send_shortcut({mods = \"CTRL\", key = \"U\", window = \"$TARGET\"})"
else
  hyprctl dispatch "hl.dsp.send_shortcut({mods = \"SHIFT\", key = \"Home\", window = \"$TARGET\"})"
  hyprctl dispatch "hl.dsp.send_shortcut({key = \"Backspace\", window = \"$TARGET\"})"
fi
