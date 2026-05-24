#!/usr/bin/env bash

HELP_FILE=$(mktemp /tmp/omanix-help-XXXXXX.md)
sed "s/{{THEME_LIST}}/$OMANIX_THEME_LIST/" "$OMANIX_DOC_STYLE" > "$HELP_FILE"

if command -v glow &> /dev/null; then
  omanix-term --class="org.omanix.terminal" -- sh -c "glow -p '$HELP_FILE'; rm '$HELP_FILE'"
else
  omanix-term --class="org.omanix.terminal" -- sh -c "less '$HELP_FILE'; rm '$HELP_FILE'"
fi
