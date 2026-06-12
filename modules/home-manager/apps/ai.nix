{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.ai;
in
{
  options.omanix.apps.ai = {
    claudeCode = {
      enable = lib.mkEnableOption "Claude Code CLI";

      disableTelemetry = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable Claude Code telemetry via environment variables";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Declarative configuration to write to ~/.claude.json";
      };
    };

    openCode = {
      enable = lib.mkEnableOption "Open Code CLI";
    };
  };

  config = lib.mkMerge [
    # --- Claude Code Configuration ---
    (lib.mkIf cfg.claudeCode.enable {
      home = {
        packages = [ pkgs.llm-agents.claude-code ];

        # Disable telemetry declaratively if requested
        sessionVariables = lib.mkIf cfg.claudeCode.disableTelemetry {
          CLAUDE_TELEMETRY = "0";
        };

        # Write configuration file if settings are provided
        file.".claude.json" = lib.mkIf (cfg.claudeCode.settings != { }) {
          text = builtins.toJSON cfg.claudeCode.settings;
        };
      };
    })

    # --- Open Code Configuration ---
    (lib.mkIf cfg.openCode.enable {
      home.packages = [ pkgs.llm-agents.opencode ];
    })
  ];
}
