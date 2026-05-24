{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.login = {
    enable = lib.mkEnableOption "Omanix login screen (SDDM)" // {
      default = true;
      description = "Whether to enable the SDDM login manager with the Omanix theme.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.login.enable) {
    programs.silentSDDM = {
      enable = true;
      theme = "catppuccin-mocha";
    };

    # Ensure SDDM always falls back to plain hyprland, not uwsm-managed session
    services.displayManager.defaultSession = "hyprland";
  };
}
