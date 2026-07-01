{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix;

  toggleScript = pkgs.writeShellApplication {
    name = "omanix-toggle-sunshine";
    runtimeInputs = with pkgs; [
      systemd
      libnotify
    ];
    text = builtins.readFile ./omanix-toggle-sunshine.sh;
  };

  tcpPorts = [
    47984
    47989
    47990
    48010
  ];
  udpPorts = [
    47998
    47999
    48000
    48002
    48010
  ];

  firewallRules = lib.concatMapStringsSep "\n" (
    ip:
    let
      tcpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -A nixos-fw -p tcp --dport ${toString port} -s ${ip} -j nixos-fw-accept"
      ) tcpPorts;
      udpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -A nixos-fw -p udp --dport ${toString port} -s ${ip} -j nixos-fw-accept"
      ) udpPorts;
    in
    "${tcpRules}\n${udpRules}"
  ) cfg.sunshine.allowedIps;

  firewallStopRules = lib.concatMapStringsSep "\n" (
    ip:
    let
      tcpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -D nixos-fw -p tcp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) tcpPorts;
      udpRules = lib.concatMapStringsSep "\n" (
        port: "iptables -D nixos-fw -p udp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) udpPorts;
    in
    "${tcpRules}\n${udpRules}"
  ) cfg.sunshine.allowedIps;

  scaledCfg = cfg.sunshine.scaledDesktop;

  # Absolute path: the Sunshine user service forces PATH=null, so prep-cmd
  # children can't resolve `hyprctl` from PATH. The service does inherit the
  # Hyprland session env (HYPRLAND_INSTANCE_SIGNATURE etc.) from the graphical
  # session, so hyprctl can still find the running compositor.
  hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";

  # The Lua parser exposes an `hl` global instead, so we
  # set the monitor by evaluating `hl.monitor{...}` at runtime. Position is
  # pinned (not "auto") so the revert restores the exact original layout.
  mkMonitorCmd =
    scale:
    ''${hyprctl} eval 'hl.monitor({ output = "${scaledCfg.monitor}", mode = "${scaledCfg.mode}", position = "${scaledCfg.position}", scale = "${scale}" })' '';

  # Default names embed the scale and monitor so the two entries are
  # self-explanatory in the Moonlight client. Overridable via scaledName /
  # nativeName. Sunshine streams the primary output regardless of which entry
  # is picked, so the monitor name is documentation for the user, not a selector.
  scaledName =
    if scaledCfg.scaledName != null then
      scaledCfg.scaledName
    else
      "Desktop (Scaled ${scaledCfg.scale}x — ${scaledCfg.monitor})";
  nativeName =
    if scaledCfg.nativeName != null then
      scaledCfg.nativeName
    else
      "Desktop (Native — ${scaledCfg.monitor})";

  scaledDesktopApp = {
    name = scaledName;
    image-path = "desktop.png";
    prep-cmd = [
      {
        do = mkMonitorCmd scaledCfg.scale;
        undo = mkMonitorCmd scaledCfg.revertScale;
      }
    ];
  };

  # Companion "native" entry: same host session, no prep-cmd, so the monitor
  # scale is left untouched at its normal 1x. Pick this in Moonlight when the
  # client is driving an external display that doesn't want the UI enlarged.
  # No `output` key — in Sunshine's apps.json `output` is a log-file path, not
  # a monitor selector; monitor choice is global / done in prep-cmd. A bare
  # name-only entry is the canonical passthrough stream.
  nativeDesktopApp = {
    name = nativeName;
    image-path = "desktop.png";
  };

  sunshineApps =
    lib.optionals scaledCfg.enable [
      scaledDesktopApp
      nativeDesktopApp
    ]
    ++ cfg.sunshine.extraApps;
in
{
  config = lib.mkIf (cfg.enable && cfg.sunshine.enable) {
    environment.systemPackages = [ toggleScript ];

    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      autoStart = false;
      # Declaring apps makes Sunshine ignore its web-UI apps.json in favour of
      # this generated, reproducible list. Only set it when we actually have
      # apps to declare, so an empty config still allows web-UI management.
      applications = lib.mkIf (sunshineApps != [ ]) {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = sunshineApps;
      };
    };

    networking.firewall.extraCommands = lib.mkIf (cfg.sunshine.allowedIps != [ ]) firewallRules;
    networking.firewall.extraStopCommands = lib.mkIf (cfg.sunshine.allowedIps != [ ]) firewallStopRules;

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
