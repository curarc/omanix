{ config, lib, pkgs, ... }:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;
  availableThemes = builtins.attrNames omanixLib.themes;
in
{
  imports = [
    ./hyprland.nix
    ./login.nix
    ./steam.nix
    ./libreoffice.nix
    ./docker.nix
    ./sunshine.nix
  ];

  options.omanix = {
    enable = lib.mkEnableOption "Omanix desktop environment";

    theme = lib.mkOption {
      type = lib.types.enum availableThemes;
      default = "tokyo-night";
      description = ''
        The active Omanix theme. This setting is inherited by Home Manager
        when using Home Manager as a NixOS module.

        Available themes: ${lib.concatStringsSep ", " availableThemes}
      '';
      example = "tokyo-night";
    };

    wallpaperIndex = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Index of the wallpaper to use from the theme's wallpaper list.";
    };

    wallpaperOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Override the theme's wallpaper with a specific local file (takes priority over index).";
    };

    activeTheme = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      description = "The fully resolved theme data (read-only, computed from omanix.theme)";
    };

    steam.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Steam and gaming tools (requires omanix.enable).";
    };
    docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Docker daemon.";
    };
    sunshine.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Sunshine game streaming server (requires omanix.enable).";
    };
    sunshine.allowedIps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of IPs or CIDR subnets allowed to connect to Sunshine (e.g. [\"192.168.1.0/24\"]).";
    };
    devenv.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the devenv CLI system-wide (requires omanix.enable).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    # Numtide binary cache for llm-agents.nix packages (Claude Code, OpenCode).
    # The default overlay builds against llm-agents' pinned nixpkgs, so these
    # cache hits avoid rebuilding the prebuilt agent binaries locally.
    nix.settings = {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    omanix.activeTheme =
      let
        baseTheme = omanixLib.themes.${cfg.theme};
        selectedWallpaper =
          if cfg.wallpaperOverride != null then
            cfg.wallpaperOverride
          else if builtins.length baseTheme.assets.wallpapers > cfg.wallpaperIndex then
            builtins.elemAt baseTheme.assets.wallpapers cfg.wallpaperIndex
          else
            builtins.elemAt baseTheme.assets.wallpapers 0;
      in
      baseTheme
      // {
        assets = baseTheme.assets // {
          wallpaper = selectedWallpaper;
        };
      };

    # ═══════════════════════════════════════════════════════════════════
    # FONT CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════
    fonts.fontconfig = {
      antialias = true;
      hinting = {
        enable = true;
        autohint = false;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };

    # ═══════════════════════════════════════════════════════════════════
    # HARDWARE
    # ═══════════════════════════════════════════════════════════════════
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # ═══════════════════════════════════════════════════════════════════
    # SERVICES
    # ═══════════════════════════════════════════════════════════════════
    services.blueman.enable = true;

    # ═══════════════════════════════════════════════════════════════════
    # SYSTEM PACKAGES
    # ═══════════════════════════════════════════════════════════════════
    # devenv CLI — available system-wide for users who want it (not used by
    # Omanix itself).
    environment.systemPackages = lib.optionals cfg.devenv.enable [ pkgs.devenv ];

    # ═══════════════════════════════════════════════════════════════════
    # PROGRAMS
    # ═══════════════════════════════════════════════════════════════════
    programs.zsh.enable = true;
  };
}
