Omanix is a NixOS port of [Omarchy](https://omarchy.org) by DHH. It brings the same curated, keyboard-driven Hyprland experience to NixOS while embracing the Nix philosophy: everything is declarative, reproducible, and configured at build time.

## What You Get

A complete Hyprland desktop out of the box:

- **Window Management** - Hyprland with sensible defaults, dwindle layout, animations, and blur
- **App Launcher** - Walker with Elephant as the data provider (apps, files, clipboard, calculator, web search, symbols)
- **Status Bar** - Waybar, fully themed, toggleable
- **Terminal** - Ghostty with Zsh, Starship prompt, and a curated set of shell tools (eza, ripgrep, fd, fzf, bat, direnv)
- **Editor** - Neovim via LazyVim with per-language support you opt into
- **Notifications** - Mako with Do Not Disturb mode
- **Lock Screen** - Hyprlock with themed clock and wallpaper blur
- **Idle Management** - Hypridle with screensaver, dimming, locking, DPMS, and suspend — all configurable
- **Screenshots** - Region/window/fullscreen capture via grim + slurp + Satty editor
- **Screen Recording** - gpu-screen-recorder with optional audio and webcam overlay
- **Theming** - Declarative themes that propagate to every component (terminal, bar, lock screen, notifications, browser chrome, btop, bat, Walker, SwayOSD)
- **Menu System** - Nested Walker-based menus for style, capture, sharing, system controls, and documentation

### Where Omanix Departs from Omarchy

Since NixOS is a fundamentally different paradigm from Arch, some things work differently:

- **No runtime theme switching.** Themes are applied at build time. You change your theme in your flake and rebuild. A preview mode lets you try wallpapers temporarily.
- **No TUI package installer.** Installing packages imperatively goes against the Nix philosophy. Everything is declared in your config.
- **Zsh instead of Bash.** Omanix uses Zsh with Oh My Zsh, autosuggestions, and syntax highlighting as the default shell.
- **Everything is a module option.** Apps, languages, visual tweaks, and idle behaviour are all configurable through typed NixOS/Home Manager options.

## Quick Start

### 1. Add Omanix to Your Flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omanix = {
      url = "github:T00fy/omanix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, omanix, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix

        # System-level module
        omanix.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.yourname = {
              imports = [ omanix.homeManagerModules.default ];
              home.stateVersion = "24.11";

              omanix = {
                user = {
                  name = "Your Name";
                  email = "you@example.com";
                };
              };
            };
          };
        }
      ];
    };
  };
}
```

### 2. Enable the System Module

In your NixOS configuration (or inline in the flake):

```nix
omanix = {
  enable = true;
  theme = "tokyo-night";    # See "Themes" below
  wallpaperIndex = 0;       # Which wallpaper from the theme to use
};
```

### 3. Rebuild

```bash
sudo nixos-rebuild switch --flake .
```

Note: Once built there's a convenience alias provided: `rebuild`

## Configuration Reference

All options live under the `omanix` namespace. Here's what you can configure.

### Theme & Wallpaper

```nix
omanix = {
  theme = "tokyo-night";
  wallpaperIndex = 1;                    # Pick a different wallpaper from the theme
  wallpaperOverride = ./my-wallpaper.jpg; # Or use your own image entirely
};
```

### Monitor Setup

```nix
omanix = {
  monitor.scale = "1.25";    # Global scale (or "auto")

  # Multi-monitor workspace mapping
  monitors = [
    { name = "DP-2";     resolution = "2560x1440"; refreshRate = 144; }
    { name = "HDMI-A-2"; resolution = "2560x1440"; refreshRate = 144; }
  ];
};
```

Each monitor gets its own set of workspaces. `Super+1-5` targets the focused monitor's workspaces. Run `hyprctl monitors` to find your monitor names.

### Hyprland Visuals

```nix
omanix.hyprland = {
  gaps.inner = 5;           # Between windows
  gaps.outer = 10;          # Screen edges
  border.size = 2;
  rounding = 0;             # Corner radius

  blur.enabled = true;
  blur.size = 2;
  blur.passes = 2;

  shadow.enabled = true;
  shadow.range = 2;

  animations.enabled = true;
};
```

### Idle & Power Management

Every stage is independently togglable and has a configurable timeout:

```nix
omanix.idle = {
  screensaver = { enable = true; timeout = 150; };   # 2.5 min
  dimScreen   = { enable = true; timeout = 840; brightness = 10; };
  lock        = { enable = true; timeout = 900; };   # 15 min
  dpms        = { enable = true; timeout = 960; };
  suspend     = { enable = true; timeout = 1800; };  # 30 min
};
```

To disable suspend entirely, set `omanix.idle.suspend.enable = false`.

### Languages

Enable language toolchains and their LSPs for Neovim:

```nix
omanix.languages = {
  nix.enable = true;          # On by default
  markdown.enable = true;     # On by default
  rust.enable = true;
  go.enable = true;
  java.enable = true;
  docker.enable = true;
  terraform.enable = true;
  typescript.enable = true;
  tailwind.enable = true;
  json.enable = true;
  dart.enable = true;
};
```

### Optional Apps

All optional apps default to `false` — enable what you need:

```nix
omanix.apps = {
  jetbrains.intellij.enable = true;
  jetbrains.rustrover.enable = true;
  obsidian.enable = true;
  whatsapp.enable = true;
  spotify.enable = true;     # Spotify
  obs.enable = true;
  neovim.enable = true;       # This one defaults to true
};
```

### Waybar

```nix
omanix.waybar = {
  modules-left = [ "hyprland/workspaces" ];
  modules-center = [ "clock" ];
  modules-right = [
    "cpu" "memory"                        # Add your own modules
    "tray" "bluetooth" "network" "pulseaudio" "battery"
  ];

  # Configure any module
  extraModuleSettings = {
    clock = { format = "{:%H:%M:%S}"; interval = 1; };
  };

  # Append custom CSS (theme variables @background, @foreground, @accent are available)
  extraStyle = ''
    #cpu { color: @accent; margin: 0 8px; }
  '';
};
```

### Extra Keybindings

```nix
omanix.hyprland = {
  extraBindings = [
    "$mainMod SHIFT, G, Open GIMP, exec, gimp"
  ];
  extraWindowRules = [
    "opacity 1 1, match:class ^(gimp)$"
  ];
  extraSettings = {
    # Any raw Hyprland setting
    general.allow_tearing = true;
  };
};
```

### System-Level Toggles

```nix
omanix = {
  enable = true;
  steam.enable = true;        # Steam + Gamescope + GameMode + MangoHud (default: true)
  docker.enable = true;       # Docker daemon + lazydocker (default: true)
  libreoffice.enable = true;  # LibreOffice (default: true)
  login.enable = true;        # SDDM with SilentSDDM theme (default: true)
};
```

## Overriding Defaults

Omanix sets opinionated defaults, but everything can be overridden using standard NixOS/Home Manager patterns:

```nix
# Override a specific setting completely
wayland.windowManager.hyprland.settings.general.gaps_in = lib.mkForce 10;

# Append to a list
wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
  "$mainMod SHIFT, P, exec, my-custom-app"
];

# Override hypridle listeners
services.hypridle.settings.listener = lib.mkForce [ /* your config */ ];
```

## Keybindings

Omanix ships with comprehensive keybindings that closely match Omarchy. Rather than listing them all here, you can:

- Press **Super+K** to open the keybindings viewer from within Omanix
- Press **Super+Alt+Space** to open the main menu, then navigate to **Learn → Keybindings**
- Refer to the [Omarchy Hotkeys Manual](https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys) — the bindings are nearly identical

## Themes

Omanix currently ships with **Tokyo Night**. Themes are defined in `lib/themes.nix` and contain everything: colour palette, wallpapers, bat syntax theme, and icon theme.

### Adding a Theme

To add a new theme, create a PR that adds an entry to `lib/themes.nix`. Each theme needs:

```nix
{
  my-theme = {
    meta = {
      name = "My Theme";
      slug = "my-theme";
      icon_theme = "Yaru-blue";      # Any icon theme available in nixpkgs
    };

    assets.wallpapers = [
      ../assets/wallpapers/my-theme/wallpaper-1.jpg
      ../assets/wallpapers/my-theme/wallpaper-2.jpg
    ];

    bat = {
      name = "theme-name";           # As listed in `bat --list-themes`
      url = "https://raw.githubusercontent.com/.../theme.tmTheme";
      sha256 = "sha256-...";
    };

    colors = {
      background = "#...";
      foreground = "#...";
      accent = "#...";
      cursor = "#...";
      selection_background = "#...";
      selection_foreground = "#...";
      color0 = "#...";  color1 = "#...";  color2 = "#...";  color3 = "#...";
      color4 = "#...";  color5 = "#...";  color6 = "#...";  color7 = "#...";
      color8 = "#...";  color9 = "#...";  color10 = "#..."; color11 = "#...";
      color12 = "#..."; color13 = "#..."; color14 = "#..."; color15 = "#...";
    };
  };
}
```

Place wallpapers in `assets/wallpapers/your-theme/` and include them in the PR.

## Contributing

Contributions are welcome! Some ideas:

- **New themes** — the easiest way to contribute. Follow the schema above and open a PR.
- **New optional apps** — add a module under `modules/home-manager/apps/`. Everything should default to `false` (or use `mkEnableOption`) so users opt in explicitly. The module should integrate with the active theme where appropriate.
- **Bug fixes and improvements** — if you find something that doesn't work or could work better, PRs and issues are appreciated.
- **Documentation** — improvements to the docs under `docs/` are always helpful.

I haven't optimized this for laptops either - because I'm personally not using this on a laptop. Things like battery/power settings are unlikely to be working. PR's addressing this are appreciated
