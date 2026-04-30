#!/usr/bin/env bash

menu_cmd() {
  local placeholder="$1"
  local options="$2"
  echo -e "$options" | "$WALKER_BIN" --dmenu --width "$OMANIX_MENU_WIDTH" --minheight 1 --maxheight "$OMANIX_MENU_MAX_HEIGHT" --placeholder "$placeholder…"
}

back_to() { "$1"; }

show_main_menu() {
  CHOICE=$(menu_cmd "Go" "󰀻  Apps\n󰧑  Learn\n󱓞  Trigger\n󰏘  Style\n󰒓  Setup\n󰍛  System")
  go_to_menu "$CHOICE"
}

go_to_menu() {
  case "${1,,}" in
    *apps*)    omanix-launch-walker ;;
    *learn*)   show_learn_menu ;;
    *trigger*) show_trigger_menu ;;
    *style*)   show_style_menu ;;
    *setup*)   show_setup_menu ;;
    *system*)  show_system_menu ;;
    *) ;;
  esac
}

show_learn_menu() {
  CHOICE=$(menu_cmd "Learn" "󰌌  Keybindings\n󰖟  Hyprland\n󱄅  NixOS Wiki\n󰊠  Neovim\n󱆃  Bash")
  case "$CHOICE" in
    *Keybindings*) omanix-menu-keybindings ;;
    *Hyprland*)    xdg-open "https://wiki.hyprland.org" ;;
    *NixOS*)       xdg-open "https://wiki.nixos.org" ;;
    *Neovim*)      xdg-open "https://neovim.io/doc/" ;;
    *Bash*)        xdg-open "https://www.gnu.org/software/bash/manual/" ;;
    *) back_to show_main_menu ;;
  esac
}

show_trigger_menu() {
  CHOICE=$(menu_cmd "Trigger" "󰄀  Capture\n󰤲  Share\n󰃉  Color Picker")
  case "$CHOICE" in
    *Capture*) show_capture_menu ;;
    *Share*)   show_share_menu ;;
    *Color*)   hyprpicker -a ;;
    *) back_to show_main_menu ;;
  esac
}

show_capture_menu() {
  CHOICE=$(menu_cmd "Capture" "󰹑  Screenshot\n󰻃  Screenrecord")
  case "$CHOICE" in
    *Screenshot*)   show_screenshot_menu ;;
    *Screenrecord*) show_screenrecord_menu ;;
    *) back_to show_trigger_menu ;;
  esac
}

show_screenshot_menu() {
  CHOICE=$(menu_cmd "Screenshot" "󰏫  Snap with Editing\n󰅍  Straight to Clipboard")
  case "$CHOICE" in
    *Editing*)   omanix-cmd-screenshot smart ;;
    *Clipboard*) omanix-cmd-screenshot smart clipboard ;;
    *) back_to show_capture_menu ;;
  esac
}

show_screenrecord_menu() {
  CHOICE=$(menu_cmd "Screenrecord" "󰍹  Record Screen\n󰍹  Record + Desktop Audio\n󰍹  Record + Microphone\n󰍹  Record + All Audio\n󰓛  Stop Recording")
  case "$CHOICE" in
    *"All Audio"*)    omanix-cmd-screenrecord --with-desktop-audio --with-microphone-audio ;;
    *"Desktop Audio"*) omanix-cmd-screenrecord --with-desktop-audio ;;
    *Microphone*)     omanix-cmd-screenrecord --with-microphone-audio ;;
    *"Record Screen"*) omanix-cmd-screenrecord ;;
    *Stop*)           omanix-cmd-screenrecord --stop-recording ;;
    *) back_to show_capture_menu ;;
  esac
}
show_share_menu() {
  CHOICE=$(menu_cmd "Share" "󰅍  Clipboard\n󰈔  File\n󰉋  Folder")
  case "$CHOICE" in
    *Clipboard*) omanix-cmd-share clipboard ;;
    *File*)      ghostty --class="org.omanix.bash" -e bash -c "omanix-cmd-share file" ;;
    *Folder*)    ghostty --class="org.omanix.bash" -e bash -c "omanix-cmd-share folder" ;;
    *) back_to show_trigger_menu ;;
  esac
}

show_style_menu() {
  CHOICE=$(menu_cmd "Style" "󰏘  Change Theme & Wallpaper\n󰈮  Read Style Guide")
  case "$CHOICE" in
    *Change*) omanix-menu-style ;;
    *Read*)   omanix-show-style-help ;;
    *) back_to show_main_menu ;;
  esac
}

show_setup_menu() {
  CHOICE=$(menu_cmd "Setup" "󰕾  Audio\n󰖩  Wifi\n󰂯  Bluetooth\n󰋁  Hyprland\n󰒲  Hypridle\n󰌾  Hyprlock\n󰍜  Waybar\n󰌧  Walker")
  case "$CHOICE" in
    *Audio*)     pavucontrol & ;;
    *Wifi*)      omanix-launch-or-focus-tui wlctl ;;
    *Bluetooth*) omanix-launch-or-focus-tui bluetui ;;
    *Hyprland*)  omanix-show-setup-help hyprland ;;
    *Hypridle*)  omanix-show-setup-help hypridle ;;
    *Hyprlock*)  omanix-show-setup-help hyprlock ;;
    *Waybar*)    omanix-show-setup-help waybar ;;
    *Walker*)    omanix-show-setup-help walker ;;
    *) back_to show_main_menu ;;
  esac
}

show_system_menu() {
  CHOICE=$(menu_cmd "System" "󰌾  Lock\n󱄄  Screensaver\n󰗽  Logout\n󰒲  Suspend\n󰜉  Restart\n󰐥  Shutdown")
  case "$CHOICE" in
    *Lock*)        omanix-lock-screen ;;
    *Screensaver*) omanix-screensaver ${OMANIX_SCREENSAVER_LOGO:+--logo "$OMANIX_SCREENSAVER_LOGO"} ;;
    *Logout*)      omanix-cmd-logout ;;
    *Suspend*)     systemctl suspend ;;
    *Restart*)     omanix-cmd-reboot ;;
    *Shutdown*)    omanix-cmd-shutdown ;;
    *) back_to show_main_menu ;;
  esac
}

if [[ -n "$1" ]]; then
  go_to_menu "$1"
else
  show_main_menu
fi
