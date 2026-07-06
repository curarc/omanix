# Dummy Display Streaming

`omanix.sunshine.dummyDisplay` streams a dedicated dummy-plug output instead
of one of your real monitors, so the stream's aspect ratio matches a specific
client (e.g. a 16:9 desktop monitor streamed to a 16:10 laptop) with no
letterboxing.

This is a niche feature. Most Omanix users streaming to a client with the
same aspect ratio as their monitor don't need it at all — if your only
problem is text/UI being too small on the client, use
`omanix.sunshine.scaledDesktop` instead.

## Prerequisites

- A free, genuinely unused output port on your GPU (DisplayPort or HDMI).
- A "dummy plug" / EDID-emulator adapter for that port — sold cheaply for
  cloud-gaming and headless-server rigs, search for "dummy plug" or "headless
  display emulator". Prices are typically $10-30.

## Why not a headless (no-hardware) virtual output?

Hyprland can create a headless virtual output (`hyprctl output create
headless <name>`) at any resolution, with no extra hardware. This was
investigated as a way to avoid buying a dummy plug, but doesn't work well
with Sunshine: Sunshine's Wayland capture can only get a plain CPU-memory
(SHM) buffer from a headless output, never a GPU-memory (DMA-BUF) handle,
because headless outputs have no real DRM/KMS backing surface. Every
hardware encoder (vaapi/nvenc/vulkan) fails to initialize against it —
Sunshine's log shows:

```
Could not initialize display with the given hw device type.
```

...and falls back to slow CPU/software encoding (`libx264`) for the whole
stream. A physical dummy plug is a genuine DRM/KMS output, so hardware
encoding works normally. If you hit that exact log message while
experimenting with a headless output yourself, this is why.

## Finding your dummy plug's connector and mode

Plug the dummy plug in, then check `hyprctl monitors` — a new output should
appear. Note its name (e.g. `DP-1`).

Check what modes it actually advertises:

```bash
hyprctl monitors -j | jq '.[] | select(.name=="DP-1") | .availableModes'
```

Many cheap dummy plugs advertise 16:9 modes only, but several also advertise
a usable non-16:9 mode out of the box (e.g. `1920x1200@60` or `2560x1600@60`
for 16:10) — look through the full list before assuming you need to flash a
custom EDID.

## Configuration

```nix
omanix.sunshine.dummyDisplay = {
  enable = true;
  connector = "DP-1";                # from hyprctl monitors, once plugged in
  mode = "2560x1600@60";              # a mode the plug's own EDID advertises
  name = "Desktop (MacBook)";         # optional — defaults to "Desktop (<connector>)"
  realMonitors = [
    { name = "DP-2";     mode = "2560x1440@144"; position = "0x0";    scale = "1"; }
    { name = "HDMI-A-2"; mode = "2560x1440@144"; position = "2560x0"; scale = "1"; }
  ];
};
```

`realMonitors` is required — the feature has no way to discover your real
monitor layout on its own. These are disabled while this Sunshine app
streams, and restored to exactly these values on disconnect.

### Avoid retyping your monitor layout

These same values are usually already declared for local Hyprland use via
`omanix.monitors` (a Home Manager option). To avoid retyping them, define
your monitor list once in your own flake — e.g. a small `monitors.nix`
exporting a plain Nix list — and import it for both `omanix.monitors` and
`dummyDisplay.realMonitors`, deriving each option's exact format from the
same source values.

## How it works

No Sunshine `output_name` setting is needed. The feature's prep-cmd disables
every monitor in `realMonitors` and enables only the dummy plug, so Sunshine's
Wayland capture auto-selects the sole enabled output — this is the same
mechanism you're already relying on if `scaledDesktop` works for you today.

## Your dummy plug and boot-time display output

Since the dummy plug is a real, always-connected display, it can end up
winning "undeclared primary output" at BIOS POST, the initrd console, or the
SDDM greeter — before Hyprland/Omanix ever runs. If you notice your boot
screens or login prompt landing on the wrong display after adding this
feature, this is why.

**Fix it by physically moving cables**, not with a kernel parameter. If your
firmware/kernel already prefers a specific port for early boot output (most
do — check by temporarily unplugging everything except one candidate and
observing which port gets BIOS POST), move your real monitor's cable into
that port and the dummy plug elsewhere.

Do **not** try to fix this with a `video=<connector>:d` kernel parameter to
force-disable the dummy plug's connector. That parameter isn't a one-time
boot hint — it permanently sets the connector's DRM force state to
disconnected for the entire session. This feature's prep-cmd tries to
re-enable that exact connector every time it streams
(`hyprctl eval hl.monitor({ disabled = false })`), and that can never succeed
against a kernel-level force-off. The result is Hyprland/DRM getting stuck
retrying against a connector the kernel insists doesn't exist — a hard hang
that only a physical reboot recovers from, not `hyprctl reload`.

## Hazards this feature works around

Building this uncovered real Hyprland behaviors worth knowing about if
you're extending this feature or debugging it:

1. **`omanix.monitors`' `position` defaults to `"auto"`**, and Hyprland
   re-flows *every* `auto`-positioned monitor whenever any monitor's enabled
   state or mode changes. Enabling the dummy plug without explicit positions
   on your real monitors can silently shift them to new positions. Set
   `position` explicitly on every entry in `omanix.monitors` if you use this
   feature.
2. **Hyprland's DRM/render thread can silently stall** if the number of
   enabled monitors ever briefly hits zero (or possibly from unthrottled
   back-to-back monitor-state changes) — `hyprctl monitors` keeps replying
   `ok` to commands while nothing actually updates on screen. `hyprctl
   reload` (not a full Hyprland restart) reliably recovers it. The
   orchestration script (`omanix-scale.sh`'s `dummy_display_on`/`_off`)
   never lets the enabled-monitor count reach zero, uses settle delays
   between monitor-state changes, and falls back to `hyprctl reload`
   automatically if a change doesn't apply within a few seconds.
3. **A kernel-level `video=<connector>:d` force-disable is unrecoverable**
   at runtime, unlike hazard #2 above — see the boot-time section above.
   This is a strictly harder failure than the DRM stall, since even
   `hyprctl reload` can't override a kernel force state.

## Testing without a live Moonlight connection

Use the "Toggle Dummy Display" entry in the System menu (`Super+Alt+Space` →
System) to manually toggle the feature and confirm it works before ever
relying on it during a real streaming session — this is recoverable from the
keyboard if something goes wrong, whereas a mid-stream failure isn't.

Or from a terminal:

```bash
omanix-scale --dummy-on
omanix-scale --dummy-off
omanix-scale --dummy-status
```
