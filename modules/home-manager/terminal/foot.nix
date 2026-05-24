{ config, lib, pkgs, ... }:
let
  cfg = config.omanix.terminal;
  theme = config.omanix.activeTheme;
  inherit (theme) colors;
  scale = config.omanix.monitor.scale;
  fontSize = if scale == "1" then 13 else 10;
  strip = c: lib.removePrefix "#" c;
in
{
  config = lib.mkIf (cfg.emulator == "foot") {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          shell = "${pkgs.zsh}/bin/zsh";
          font = "${config.omanix.font}:size=${toString fontSize}";
          pad = "14x14";
          dpi-aware = "no";
        };
        tweak = {
          grapheme-width-method = "max";
        };
        cursor = {
          style = "block";
          blink = "no";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        scrollback = {
          multiplier = toString (builtins.floor cfg.mouseScrollMultiplier);
        };
        colors-dark = {
          background = strip colors.background;
          foreground = strip colors.foreground;
          cursor = "${strip colors.background} ${strip colors.cursor}";
          regular0 = strip colors.color0;
          regular1 = strip colors.color1;
          regular2 = strip colors.color2;
          regular3 = strip colors.color3;
          regular4 = strip colors.color4;
          regular5 = strip colors.color5;
          regular6 = strip colors.color6;
          regular7 = strip colors.color7;
          bright0 = strip colors.color8;
          bright1 = strip colors.color9;
          bright2 = strip colors.color10;
          bright3 = strip colors.color11;
          bright4 = strip colors.color12;
          bright5 = strip colors.color13;
          bright6 = strip colors.color14;
          bright7 = strip colors.color15;
          selection-foreground = strip colors.selection_foreground;
          selection-background = strip colors.selection_background;
        };
      };
    };
  };
}
