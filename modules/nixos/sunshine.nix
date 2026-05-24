{
  config,
  lib,
  ...
}:
let
  cfg = config.omanix;

  tcpPorts = [ 47984 47989 47990 48010 ];
  udpPorts = [ 47998 47999 48000 48002 48010 ];

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
        port:
        "iptables -D nixos-fw -p tcp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) tcpPorts;
      udpRules = lib.concatMapStringsSep "\n" (
        port:
        "iptables -D nixos-fw -p udp --dport ${toString port} -s ${ip} -j nixos-fw-accept || true"
      ) udpPorts;
    in
    "${tcpRules}\n${udpRules}"
  ) cfg.sunshine.allowedIps;
in
{
  config = lib.mkIf (cfg.enable && cfg.sunshine.enable) {
    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      autoStart = true;
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
