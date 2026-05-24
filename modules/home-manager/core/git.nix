{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git user name used for commits.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address used for commits.";
    };
  };

  config = {
    programs.git = {
      enable = true;

      settings = {
        user = {
          inherit (cfg.user) name;
          inherit (cfg.user) email;
        };
        init.defaultBranch = "main";
        core.editor = "nvim";
      };
    };
  };
}
