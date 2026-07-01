#!/usr/bin/env bash

# 1. Ensure background services are running
# Elephant is the data provider for Walker
if ! pgrep -x elephant > /dev/null; then
  systemctl --user start elephant.service
  sleep 0.5
fi

# Ensure walker service (the background daemon) is running
if ! pgrep -f "walker --gapplication-service" > /dev/null; then
  systemctl --user start walker.service
  sleep 0.3
fi

# 2. Pick dimensions/theme for this invocation. omanix-scale (runtime
# Moonlight UI-scale toggle) flips a state file rather than restarting the
# walker service — walker reads --theme/--width/--maxheight/--minheight
# fresh on each launch, so no restart is needed to switch between them.
if [[ -f "${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active" ]]; then
  WIDTH="$OMANIX_WALKER_SCALED_WIDTH"
  HEIGHT="$OMANIX_WALKER_SCALED_HEIGHT"
  THEME="omanix-scaled"
else
  WIDTH="$OMANIX_WALKER_WIDTH"
  HEIGHT="$OMANIX_WALKER_HEIGHT"
  THEME="omanix-default"
fi

# 3. Launch Walker with the resolved dimensions/theme
# We use the WALKER_BIN variable injected by the Nix wrapper
exec "${WALKER_BIN:-walker}" --theme "$THEME" --width "$WIDTH" --maxheight "$HEIGHT" --minheight "$HEIGHT" "$@"
