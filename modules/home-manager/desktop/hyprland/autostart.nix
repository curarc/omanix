{ config, pkgs, ... }:
let
  inherit (config.omanix.activeTheme.assets) wallpaper;
in
{
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE GDK_SCALE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
      hl.exec_cmd("mako")
      hl.exec_cmd("swayosd-server")
      hl.exec_cmd("systemctl --user start hyprpolkitagent")
      hl.exec_cmd("wl-paste --type text --watch cliphist store")
      hl.exec_cmd("wl-paste --type image --watch cliphist store")
      hl.exec_cmd("${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill")
    end)
  '';
}
