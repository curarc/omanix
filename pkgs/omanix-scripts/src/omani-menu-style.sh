#!/usr/bin/env bash

THEME_NAME=$(jq -r 'keys[]' "$OMANIX_THEMES_FILE" | "$WALKER_BIN" --dmenu --placeholder "Select Theme...")
[ -z "$THEME_NAME" ] && exit 0

PRESETS=$(jq -r --arg t "$THEME_NAME" '.[$t] | to_entries | .[] | "\(.key): \(.value)"' "$OMANIX_THEMES_FILE")

SELECTION=$(echo -e "[Custom]: Use your own image file...\n$PRESETS" | \
  "$WALKER_BIN" --dmenu --placeholder "Select Wallpaper for $THEME_NAME...")

[ -z "$SELECTION" ] && exit 0

if [[ "$SELECTION" == "[Custom]"* ]]; then
  if command -v glow &> /dev/null; then
    omanix-term --class="org.omanix.terminal" -- sh -c "glow -p '$OMANIX_DOC_STYLE_OVERRIDE'"
  else
    omanix-term --class="org.omanix.terminal" -- sh -c "less '$OMANIX_DOC_STYLE_OVERRIDE'"
  fi
  exit 0
fi

WP_INDEX=$(echo "$SELECTION" | cut -d: -f1)
WP_PATH=$(echo "$SELECTION" | cut -d: -f2 | xargs)

pkill swaybg
swaybg -i "$WP_PATH" -m fill &

export THEME_NAME
export WP_INDEX

HELP_TEXT=$(envsubst < "$OMANIX_DOC_STYLE_PREVIEW")

TMP_HELP=$(mktemp)
echo "$HELP_TEXT" > "$TMP_HELP"

omanix-term --class="org.omanix.terminal" -- sh -c "glow -p '$TMP_HELP'; rm '$TMP_HELP'"
