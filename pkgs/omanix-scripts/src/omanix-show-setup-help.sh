#!/usr/bin/env bash

TOPIC="$1"

case "$TOPIC" in
  hyprland)  DOC_FILE="$OMANIX_DOCS_DIR/hyprland.md" ;;
  hypridle)  DOC_FILE="$OMANIX_DOCS_DIR/hypridle.md" ;;
  hyprlock)  DOC_FILE="$OMANIX_DOCS_DIR/hyprlock.md" ;;
  waybar)    DOC_FILE="$OMANIX_DOCS_DIR/waybar.md" ;;
  walker)    DOC_FILE="$OMANIX_DOCS_DIR/walker.md" ;;
  *)
    echo "Unknown topic: $TOPIC"
    exit 1
    ;;
esac

if command -v glow &> /dev/null; then
  omanix-term --class="org.omanix.terminal" -- sh -c "glow -p '$DOC_FILE'"
else
  omanix-term --class="org.omanix.terminal" -- sh -c "less '$DOC_FILE'"
fi
