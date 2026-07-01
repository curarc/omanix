{ config, lib, pkgs, ... }:
let
  cfg = config.omanix.terminal;

  emulators = {
    ghostty = { pkg = pkgs.ghostty; classFlag = "--class"; execFlag = "-e"; };
    foot = { pkg = pkgs.foot; classFlag = "--app-id"; execFlag = null; };
  };

  emu = emulators.${cfg.emulator};

  execLine = if emu.execFlag != null
    then ''exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}" ${emu.execFlag} "''${CMD[@]}"''
    else ''exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}" "''${CMD[@]}"'';

  # foot has no signal/IPC to live-resize the font of an already-open
  # window (only SIGUSR1/2, for the color theme) — see
  # modules/home-manager/terminal/foot.nix. So the scaled font only applies
  # to NEW windows, via a CLI override on launch, gated on the same state
  # file omanix-scale (runtime Moonlight UI-scale toggle) uses. Revisit if
  # foot ever gains a live font-resize API.
  scaledFootArgs = lib.optionalString (cfg.emulator == "foot") ''
    if [[ -f "''${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active" ]]; then
      ARGS+=(-o "main.font=${config.omanix.font}:size=${toString cfg.scaledFontSize}")
    fi
  '';

  terminalWrapper = pkgs.writeShellScriptBin "omanix-term" ''
    CLASS=""
    CWD=""
    CMD=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --class=*) CLASS="''${1#--class=}"; shift ;;
        --cwd=*) CWD="''${1#--cwd=}"; shift ;;
        --) shift; CMD=("$@"); break ;;
        *) CMD=("$@"); break ;;
      esac
    done
    ARGS=()
    [[ -n "$CLASS" ]] && ARGS+=(${emu.classFlag}="$CLASS")
    [[ -n "$CWD" ]] && ARGS+=(--working-directory="$CWD")
    ${scaledFootArgs}
    if [[ ''${#CMD[@]} -gt 0 ]]; then
      ${execLine}
    else
      exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}"
    fi
  '';
in
{
  imports = [
    ./ghostty.nix
    ./foot.nix
  ];

  options.omanix.terminal = {
    emulator = lib.mkOption {
      type = lib.types.enum [ "ghostty" "foot" ];
      default = "ghostty";
      description = "Which terminal emulator to use.";
    };

    mouseScrollMultiplier = lib.mkOption {
      type = lib.types.float;
      default = 5.0;
      description = "Mouse scroll multiplier. Higher values scroll more lines per tick.";
    };

    bin = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = cfg.emulator;
      description = "Terminal binary name.";
    };

    wrapper = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = terminalWrapper;
      description = "The omanix-term wrapper package.";
    };
  };

  config = {
    home.packages = [
      terminalWrapper
    ];
  };
}
