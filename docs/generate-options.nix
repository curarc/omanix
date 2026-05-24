{
  pkgs,
  lib,
  self,
  inputs,
  home-manager,
  omanixLib,
}:
let
  # Evaluate NixOS module (full nixosSystem gives us all infrastructure)
  nixosEval = lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.default
      { omanix.enable = true; }
    ];
  };

  # Evaluate Home Manager module
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
in
pkgs.runCommand "omanix-options-docs" { } ''
  mkdir -p $out
  cat > $out/options.md << 'HEADER'
  # Omanix Options Reference

  ## NixOS Module Options

  These options are available under `omanix.*` in your NixOS configuration.

  HEADER
  cat ${nixosDocs.optionsCommonMark} >> $out/options.md

  cat >> $out/options.md << 'SEPARATOR'

  ## Home Manager Module Options

  These options are available under `omanix.*` in your Home Manager configuration.

  SEPARATOR
  cat ${hmDocs.optionsCommonMark} >> $out/options.md
''
