{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.jetbrains;

  # ---------------------------------------------------------------------------
  # EAP package builder (buildFHSEnv wrapper around official tarball)
  # ---------------------------------------------------------------------------
  mkJetBrainsEap =
    {
      pname,
      version,
      buildNumber,
      hash,
      # URL path segment, e.g. "idea" for ideaIU, "rustrover" for RustRover
      urlProduct,
      # Tarball filename prefix, e.g. "ideaIU" or "RustRover"
      tarballPrefix,
      # The native launcher binary inside bin/, e.g. "idea" or "rustrover"
      launcher,
      wmClass,
    }:
    let
      # Extract the IDE into its own derivation so it has a stable /nix/store path.
      unwrapped = pkgs.stdenv.mkDerivation {
        pname = "${pname}-unwrapped";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://download.jetbrains.com/${urlProduct}/${tarballPrefix}-${buildNumber}.tar.gz";
          inherit hash;
        };
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          mkdir -p $out
          cp -r . $out/
        '';
        sourceRoot = ".";
        unpackPhase = ''
          tar xf $src --strip-components=1
        '';
      };
    in
    pkgs.buildFHSEnv {
      name = pname;

      runScript = "${unwrapped}/bin/${launcher}";

      profile = ''
        export XCURSOR_SIZE=''${XCURSOR_SIZE:-24}
        export XCURSOR_THEME=''${XCURSOR_THEME:-default}
      '';

      targetPkgs =
        p: with p; [
          zlib
          glib
          gtk3
          gtk4
          libGL
          freetype
          fontconfig
          dbus
          nss
          nspr
          alsa-lib
          cups
          libdrm
          mesa
          vulkan-loader
          wayland
          libxkbcommon
          libx11
          libXext
          libxi
          libxrender
          libxtst
          libxrandr
          libxcursor
          libxdamage
          libxfixes
          libxcomposite
          libxinerama
          libxcb
          # ---
          libsecret
          e2fsprogs
          libnotify
          udev
          at-spi2-atk
          cairo
          pango
          expat
          gdk-pixbuf
          git
          coreutils
        ];

      extraInstallCommands = ''
        # .desktop entry
        mkdir -p $out/share/applications
        cat > $out/share/applications/${pname}.desktop <<EOF
        [Desktop Entry]
        Name=${pname} (EAP)
        Exec=$out/bin/${pname}
        Icon=${unwrapped}/bin/${launcher}.svg
        Type=Application
        Categories=Development;IDE;
        StartupWMClass=${wmClass}
        EOF

        if [ -f "${unwrapped}/bin/${launcher}.svg" ]; then
          mkdir -p $out/share/pixmaps
          ln -sf "${unwrapped}/bin/${launcher}.svg" $out/share/pixmaps/${pname}.svg
        fi
      '';
    };

  # ---------------------------------------------------------------------------
  # Reusable EAP option type
  # ---------------------------------------------------------------------------
  mkEapOptions = ideName: {
    enable = lib.mkEnableOption "Use ${ideName} EAP instead of stable";
    buildNumber = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "EAP build number (e.g. \"261.20362.25\"). Required when eap.enable = true.";
      example = "261.20362.25";
    };
    hash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        SRI hash of the EAP tarball. Get it with:
          nix-prefetch-url --type sha256 --unpack <url> | nix hash convert --to sri --hash-algo sha256
        Required when eap.enable = true.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  # ---------------------------------------------------------------------------
  # Stable helpers
  # ---------------------------------------------------------------------------
  mkMajorMinor =
    pkg:
    let
      parts = lib.splitString "." pkg.version;
    in
    "${builtins.elemAt parts 0}.${builtins.elemAt parts 1}";

  baseVmOptions = [
    "-Dawt.toolkit.name=WLToolkit"
  ];

  mkVmOptionsContent = extraOpts: lib.concatStringsSep "\n" (baseVmOptions ++ extraOpts);

  # ---------------------------------------------------------------------------
  # Resolved packages (EAP or stable)
  # ---------------------------------------------------------------------------
  intellijPkg =
    if cfg.intellij.eap.enable then
      mkJetBrainsEap {
        pname = "intellij-idea-eap";
        version = "eap-${cfg.intellij.eap.buildNumber}";
        inherit (cfg.intellij.eap) buildNumber hash;
        urlProduct = "idea";
        tarballPrefix = "idea";
        launcher = "idea";
        wmClass = "jetbrains-idea";
      }
    else
      pkgs.jetbrains.idea;

  rustRoverPkg =
    if cfg.rustrover.eap.enable then
      mkJetBrainsEap {
        pname = "rustrover-eap";
        version = "eap-${cfg.rustrover.eap.buildNumber}";
        inherit (cfg.rustrover.eap) buildNumber hash;
        urlProduct = "rustrover";
        tarballPrefix = "RustRover";
        launcher = "rustrover";
        wmClass = "jetbrains-rustrover";
      }
    else
      pkgs.jetbrains.rust-rover;

in
{
  options.omanix.apps.jetbrains = {
    intellij = {
      enable = lib.mkEnableOption "IntelliJ IDEA";
      eap = mkEapOptions "IntelliJ IDEA";
      extraVmOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra JVM options for IntelliJ IDEA (e.g. [\"-Xmx4g\"])";
        example = [
          "-Xmx4g"
          "-Xms1g"
        ];
      };
    };
    rustrover = {
      enable = lib.mkEnableOption "JetBrains RustRover";
      eap = mkEapOptions "RustRover";
      extraVmOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra JVM options for RustRover (e.g. [\"-Xmx4g\"])";
        example = [
          "-Xmx4g"
          "-Xms1g"
        ];
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.intellij.eap.enable && !cfg.intellij.enable);
          message = "omanix.apps.jetbrains.intellij.eap.enable requires intellij.enable = true";
        }
        {
          assertion = !(cfg.intellij.eap.enable && cfg.intellij.eap.buildNumber == "");
          message = "omanix.apps.jetbrains.intellij.eap.buildNumber must be set when eap is enabled";
        }
        {
          assertion = !(cfg.intellij.eap.enable && cfg.intellij.eap.hash == "");
          message = "omanix.apps.jetbrains.intellij.eap.hash must be set when eap is enabled";
        }
        {
          assertion = !(cfg.rustrover.eap.enable && !cfg.rustrover.enable);
          message = "omanix.apps.jetbrains.rustrover.eap.enable requires rustrover.enable = true";
        }
        {
          assertion = !(cfg.rustrover.eap.enable && cfg.rustrover.eap.buildNumber == "");
          message = "omanix.apps.jetbrains.rustrover.eap.buildNumber must be set when eap is enabled";
        }
        {
          assertion = !(cfg.rustrover.eap.enable && cfg.rustrover.eap.hash == "");
          message = "omanix.apps.jetbrains.rustrover.eap.hash must be set when eap is enabled";
        }
      ];
    }

    (lib.mkIf (cfg.intellij.enable || cfg.rustrover.enable) {
      home.packages = lib.flatten [
        (lib.optional cfg.intellij.enable intellijPkg)
        (lib.optional cfg.rustrover.enable rustRoverPkg)
      ];

      xdg.configFile = lib.mkMerge [
        (lib.mkIf (cfg.intellij.enable && !cfg.intellij.eap.enable) {
          "JetBrains/IntelliJIdea${mkMajorMinor pkgs.jetbrains.idea}/idea64.vmoptions" = {
            text = mkVmOptionsContent cfg.intellij.extraVmOptions;
            force = true;
          };
        })
        (lib.mkIf (cfg.rustrover.enable && !cfg.rustrover.eap.enable) {
          "JetBrains/RustRover${mkMajorMinor pkgs.jetbrains.rust-rover}/rustrover64.vmoptions" = {
            text = mkVmOptionsContent cfg.rustrover.extraVmOptions;
            force = true;
          };
        })
      ];
    })
  ];
}
