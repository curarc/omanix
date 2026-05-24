{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.gh;
in
{
  options.omanix.apps.gh = {
    enable = lib.mkEnableOption "GitHub CLI";

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing a GitHub OAuth token (e.g. config.sops.secrets.github_pat.path).";
    };

    gitProtocol = lib.mkOption {
      type = lib.types.enum [
        "https"
        "ssh"
      ];
      default = "https";
      description = "Protocol to use for git operations (https or ssh).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = cfg.gitProtocol;
          prompt = "enabled";
        };
      };
    }

    (lib.mkIf (cfg.tokenFile != null) {
      # Write hosts.yml at activation time so the runtime sops secret is available.
      home.activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.config/gh"
        install -m 600 /dev/null "$HOME/.config/gh/hosts.yml"
        printf 'github.com:\n    oauth_token: %s\n    git_protocol: ${cfg.gitProtocol}\n' \
          "$(cat ${cfg.tokenFile})" > "$HOME/.config/gh/hosts.yml"
      '';
    })
  ]);
}
