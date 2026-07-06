{ lib }:
{
  # Expose color utils
  colors = import ./color-utils.nix { inherit lib; };

  # Expose themes (data only, doesn't need lib)
  themes = import ./themes.nix;

  # Expose dummyDisplay helpers (shared derivation logic between
  # modules/nixos/sunshine.nix and modules/home-manager/scripts/default.nix)
  dummyDisplay = import ./dummy-display.nix { inherit lib; };
}
