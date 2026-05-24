{
  pkgs,
  lib,
  self,
  inputs,
  home-manager,
  omanixLib,
}:
let
  nixosEval = lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.default
      { omanix.enable = true; }
    ];
  };

  hmEval = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      self.homeManagerModules.default
      {
        home.username = "docs";
        home.homeDirectory = "/home/docs";
        home.stateVersion = "24.11";
        omanix.user.name = "docs";
        omanix.user.email = "docs@example.com";
      }
    ];
  };

  filterOmanix = opt:
    let
      isActiveTheme = lib.hasPrefix "omanix.activeTheme" opt.name or "";
    in
    opt // {
      declarations = [ ];
      visible = if isActiveTheme || (opt.internal or false) || (opt.readOnly or false) then false else opt.visible or true;
    };

  nixosDocs = pkgs.nixosOptionsDoc {
    options = nixosEval.options.omanix;
    transformOptions = filterOmanix;
    warningsAreErrors = false;
  };

  hmDocs = pkgs.nixosOptionsDoc {
    options = hmEval.options.omanix;
    transformOptions = filterOmanix;
    warningsAreErrors = false;
  };

  splitScript = pkgs.writeShellScript "split-options" ''
    set -euo pipefail
    NIXOS_JSON="$1"
    HM_JSON="$2"
    OUT="$3"

    mkdir -p "$OUT"

    ${pkgs.python3}/bin/python3 ${./split-options.py} "$NIXOS_JSON" "$HM_JSON" "$OUT"
  '';
in
pkgs.runCommand "omanix-options-docs" { } ''
  ${splitScript} ${nixosDocs.optionsJSON}/share/doc/nixos/options.json ${hmDocs.optionsJSON}/share/doc/nixos/options.json $out
  cp ${./getting-started.md} $out/getting-started.md
  cp ${./configuration.md} $out/configuration.md
''
