{
  description = "Omanix - Omarchy for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland/v0.53.3";

    nix-colors.url = "github:misterio77/nix-colors";

    lazyvim.url = "github:pfassina/lazyvim-nix/v15.13.0";

    elephant.url = "github:abenz1267/elephant";

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    spotatui = {
      url = "github:LargeModGames/spotatui";
      flake = false;
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yt-dlp-src = {
      url = "github:yt-dlp/yt-dlp";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      lazyvim,
      walker,
      elephant,
      silentSDDM,
      wlctl,
      ...
    }@inputs:
    let
      omanixLib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      lib = omanixLib;

      # ═══════════════════════════════════════════════════════════════════
      # NixOS Module (system-level configuration)
      # ═══════════════════════════════════════════════════════════════════

      overlays.default = final: prev: {
        spotatui = prev.callPackage inputs.spotatui { };
        omanix-screensaver = final.callPackage ./pkgs/omanix-screensaver { };
        omanix-scripts = final.callPackage ./pkgs/omanix-scripts { };
        wlctl = inputs.wlctl.packages.${prev.system}.default;

        yt-dlp = prev.yt-dlp.overrideAttrs (oldAttrs: {
          src = inputs.yt-dlp-src;
          version = "master";
          doCheck = false;
        });
      };

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            ./modules/nixos
            silentSDDM.nixosModules.default
          ];

          nixpkgs.overlays = [ self.overlays.default ];
        };

      # ═══════════════════════════════════════════════════════════════════
      # Home Manager Module (user-level configuration)
      # ═══════════════════════════════════════════════════════════════════
      homeManagerModules.default =
        {
          config,
          pkgs,
          lib,
          osConfig ? null,
          ...
        }:
        {
          imports = [
            ./modules/home-manager
            lazyvim.homeManagerModules.default
            walker.homeManagerModules.default
          ];

          _module.args.omanixLib = omanixLib;
          _module.args.inputs = inputs;
        };
    };
}
