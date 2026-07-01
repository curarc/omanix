{
  pkgs,
  inputs,
  config,
  lib,
  omanixLib,
  ...
}:
let
  availableThemes = builtins.attrNames omanixLib.themes;
  themeListFormatted = builtins.concatStringsSep "\\n" (map (t: "- ${t}") availableThemes);

  themesJson = pkgs.writeText "omanix-themes.json" (
    builtins.toJSON (builtins.mapAttrs (_name: val: val.assets.wallpapers) omanixLib.themes)
  );

  docStylePreview = pkgs.writeText "style-preview.md" (
    builtins.readFile ../../../docs/style-preview.md
  );
  docStyleOverride = pkgs.writeText "style-override.md" (
    builtins.readFile ../../../docs/style-override.md
  );
  docStyleGeneral = ../../../docs/style.md;
  docsDir = ../../../docs;
  screensaverLogo = config.omanix.idle.screensaver.logo;

  gapsOuter = toString config.omanix.hyprland.gaps.outer;
  gapsInner = toString config.omanix.hyprland.gaps.inner;
  borderSize = toString config.omanix.hyprland.border.size;

  activeTheme = config.omanix.activeTheme;
  wallpaperList = builtins.concatStringsSep "\n" (map toString activeTheme.assets.wallpapers);

  monitorMap = lib.concatStringsSep ":" (
    lib.imap0 (idx: mon: "${mon.name}=${toString (idx * 10)}") config.omanix.monitors
  );

  omanixScripts = pkgs.omanix-scripts.override {
    walker = inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default;
    terminalWrapper = config.omanix.terminal.wrapper;
    inherit
      themesJson
      docStylePreview
      docStyleOverride
      docStyleGeneral
      docsDir
      themeListFormatted
      screensaverLogo
      ;
    inherit
      gapsOuter
      gapsInner
      borderSize
      wallpaperList
      monitorMap
      ;
    walkerWidth = toString config.omanix.walker.width;
    walkerHeight = toString config.omanix.walker.height;
    walkerScaledWidth = toString config.omanix.walker.scaledWidth;
    walkerScaledHeight = toString config.omanix.walker.scaledHeight;
    menuWidth = toString config.omanix.menu.width;
    menuMaxHeight = toString config.omanix.menu.maxHeight;
  };
in
{
  imports = [
    ./screensaver.nix
  ];

  home.packages = with pkgs; [
    omanixScripts
    config.omanix.browser.package

    # ─────────────────────────────────────────────────────────────────
    # Script runtime dependencies (used by omanix-scripts at runtime)
    # ─────────────────────────────────────────────────────────────────
    jq
    procps
    grim
    slurp
    wl-clipboard
    libnotify
    hyprpicker
    wayfreeze
    libxkbcommon
    gawk
    gnused
    envsubst
    swaybg
    wlctl
    glow

    # ─────────────────────────────────────────────────────────────────
    # Media / hardware control (no useful HM modules for these)
    # ─────────────────────────────────────────────────────────────────
    playerctl
    brightnessctl
    wireplumber

    # ─────────────────────────────────────────────────────────────────
    # Screen recording toolchain
    # ─────────────────────────────────────────────────────────────────
    wl-screenrec

    # ─────────────────────────────────────────────────────────────────
    # Standalone apps (no dedicated omanix module yet)
    # ─────────────────────────────────────────────────────────────────
    nautilus
    fastfetch
    chromium
    bitwarden-cli
    localsend
    bluetui
    networkmanagerapplet
  ];
}
