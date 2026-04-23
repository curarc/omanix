{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  config = lib.mkIf cfg.enable {
    # Disable UWSM-managed Hyprland session — it causes a kernel DRM master
    # deadlock when SDDM selects it (Weston holds DRM master while uwsm's
    # async systemd startup races to acquire it, freezing the entire system
    # with no TTY escape possible).
    programs.hyprland.withUWSM = false;
  };
}
