{ lib }:
rec {
  # Sum of realMonitors' widths (parsed from each "WIDTHxHEIGHT@RATE" mode
  # string). Used to compute a default dummy-plug position that always lands
  # just past the right edge of the real desktop, non-overlapping regardless
  # of how many real monitors are declared.
  realMonitorsTotalWidth =
    realMonitors:
    lib.foldl' (
      acc: mon: acc + (lib.toInt (builtins.head (builtins.match "([0-9]+)x.*" mon.mode)))
    ) 0 realMonitors;

  # Resolves omanix.sunshine.dummyDisplay.position: the configured value if
  # set, otherwise computed from realMonitors' extents. Shared between the
  # NixOS-level instance (modules/nixos/sunshine.nix) and the home-manager
  # bridge (modules/home-manager/scripts/default.nix) so the two never
  # disagree on the default.
  resolvePosition =
    { position, realMonitors }:
    if position != null then
      position
    else
      "${toString (realMonitorsTotalWidth realMonitors)}x0";

  # Newline-separated "name|mode|position|scale" lines for realMonitors, the
  # convention omanix-scale.sh expects in OMANIX_DUMMY_DISPLAY_REAL_MONITORS.
  realMonitorsEnv =
    realMonitors:
    lib.concatMapStringsSep "\n" (mon: "${mon.name}|${mon.mode}|${mon.position}|${mon.scale}") realMonitors;
}
