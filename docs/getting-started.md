# Getting Started

## Add Omanix to Your Flake

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

## Enable the System Module

In your NixOS configuration (or inline in the flake):

```nix
omanix = {
  enable = true;
  theme = "tokyo-night";
  wallpaperIndex = 0;
};
```

## Rebuild

```bash
sudo nixos-rebuild switch --flake .
```

Once built there's a convenience alias provided: `rebuild`
