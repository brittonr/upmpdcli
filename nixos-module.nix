{ lib, ... }:
let
  inherit (lib) mkDefault;
  inherit (lib.types) attrsOf anything;
in
{
  _class = "clan.service";
  manifest = {
    name = "upmpdcli";
    readme = ''
      UPnP Media Renderer frontend for MPD with streaming service support

      Features:
      - UPnP/DLNA Media Renderer that controls MPD
      - Tidal HiRes streaming (up to HI_RES_LOSSLESS quality)
      - Qobuz, Subsonic, and other streaming services
      - Works perfectly with rmpc and other MPD clients
      - Media Server mode for browsing streaming services

      Using with rmpc:
      1. Connect to MPD as usual: rmpc -h <host> -p 6600
      2. Streaming content appears in MPD library after browsing via UPnP
      3. Full MPD protocol support (unlike Mopidy's limited implementation)

      Tidal Setup:
      1. Enable Tidal in settings
      2. Complete OAuth login via logs or web interface
      3. Browse Tidal content through UPnP control point or media server
    '';
  };

  roles = {
    server = {
      description = "UPnP Media Renderer frontend for MPD";
      interface = {
        # Freeform module - any attribute becomes a upmpdcli setting
        freeformType = attrsOf anything;
      };

      perInstance =
        { extendSettings, ... }:
        {
          nixosModule =
            { pkgs, config, ... }:
            let
              # Build dependencies
              libnpupnp = pkgs.callPackage ./libnpupnp.nix { };
              libupnpp = pkgs.callPackage ./libupnpp.nix { inherit libnpupnp; };

              # Python environment for upmpdcli plugins
              pythonEnv = pkgs.python3.withPackages (
                ps: with ps; [
                  requests
                  tidalapi
                  bottle # For web interface
                ]
              );

              # Build upmpdcli package if not available in nixpkgs
              upmpdcli = pkgs.stdenv.mkDerivation rec {
                pname = "upmpdcli";
                version = "1.9.7";

                src = pkgs.fetchurl {
                  url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
                  hash = "sha256-06z6fyjq5g1g1gq9zj9klwl87zmn0pnricrihhf3hjvr2pakjgmi";
                };

                nativeBuildInputs = with pkgs; [
                  pkg-config
                  pythonEnv
                ];

                buildInputs = with pkgs; [
                  curl
                  jsoncpp
                  libmpdclient
                  libmicrohttpd
                  libupnpp
                  pythonEnv
                ];

                # Ensure plugins can find Python modules
                postInstall = ''
                  # Create wrapper scripts for Python plugins to find modules
                  wrapProgram() {
                    local prog="$1"
                    local wrapped="$prog.wrapped"

                    if [ -f "$prog" ]; then
                      mv "$prog" "$wrapped"
                      cat > "$prog" <<EOF
                  #!/bin/sh
                  export PYTHONPATH="${pythonEnv}/${pythonEnv.sitePackages}:\$PYTHONPATH"
                  exec "$wrapped" "\$@"
                  EOF
                      chmod +x "$prog"
                    fi
                  }

                  # Find and wrap any Python plugin scripts
                  for plugin in $out/share/upmpdcli/cdplugins/*; do
                    if [ -d "$plugin" ]; then
                      for script in "$plugin"/*.py; do
                        if [ -f "$script" ]; then
                          wrapProgram "$script"
                        fi
                      done
                    fi
                  done
                '';

                meta = with lib; {
                  description = "UPnP Media Renderer front-end for MPD with Tidal support";
                  homepage = "https://www.lesbonscomptes.com/upmpdcli/";
                  license = licenses.gpl2Plus;
                  platforms = platforms.linux;
                };
              };

              localSettings = extendSettings {
                # Basic settings

                # MPD connection settings
                mpdHost = mkDefault "localhost";
                mpdPort = mkDefault 6600;
                mpdPassword = mkDefault null;

                # UPnP settings
                friendlyName = mkDefault "upmpdcli @ %h";
                upnpPort = mkDefault 0; # 0 = auto-select
                upnpLogLevel = mkDefault 2;

                # Media server settings
                enableMediaServer = mkDefault true;
                mediaServerPort = mkDefault 9790;

                # Tidal settings
                tidalEnable = mkDefault false;
                tidalQuality = mkDefault "LOSSLESS"; # LOW, HIGH, LOSSLESS, HI_RES_LOSSLESS
                tidalLoginMethod = mkDefault "OAUTH"; # OAUTH or PKCE

                # Qobuz settings
                qobuzEnable = mkDefault false;

                # Subsonic settings
                subsonicEnable = mkDefault false;

                # Cache directory
                cacheDir = mkDefault "/var/cache/upmpdcli";

                # Extra configuration
                extraConfig = mkDefault "";
              };

              configFile = pkgs.writeText "upmpdcli.conf" ''
                # MPD connection
                mpdhost = ${localSettings.mpdHost}
                mpdport = ${toString localSettings.mpdPort}
                ${if localSettings.mpdPassword != null then "mpdpassword = ${localSettings.mpdPassword}" else ""}

                # UPnP settings
                friendlyname = ${localSettings.friendlyName}
                upnpport = ${toString localSettings.upnpPort}
                upnploglevel = ${toString localSettings.upnpLogLevel}

                # Cache directory
                cachedir = ${localSettings.cacheDir}

                # Media Server
                ${
                  if localSettings.enableMediaServer then
                    ''
                      msmode = 1
                      msmediadir = /var/lib/upmpdcli/media
                      msport = ${toString localSettings.mediaServerPort}
                    ''
                  else
                    ""
                }

                # Tidal plugin
                ${
                  if localSettings.tidalEnable then
                    ''
                      tidalenable = 1
                      tidalquality = ${localSettings.tidalQuality}
                      tidalloginmethod = ${localSettings.tidalLoginMethod}
                    ''
                  else
                    "tidalenable = 0"
                }

                # Qobuz plugin
                ${
                  if localSettings.qobuzEnable then
                    ''
                      qobuzenable = 1
                    ''
                  else
                    "qobuzenable = 0"
                }

                # Subsonic plugin
                ${
                  if localSettings.subsonicEnable then
                    ''
                      subsonicenable = 1
                    ''
                  else
                    "subsonicenable = 0"
                }

                # Extra configuration
                ${localSettings.extraConfig}
              '';
            in
            {
              # Create upmpdcli user
              users.users.upmpdcli = {
                description = "upmpdcli daemon user";
                group = "audio";
                isSystemUser = true;
                home = "/var/lib/upmpdcli";
                createHome = true;
              };

              # Install upmpdcli package
              environment.systemPackages = [ upmpdcli ];

              # Create systemd service
              systemd.services.upmpdcli = {
                description = "UPnP Media Renderer front-end for MPD";
                after = [
                  "network.target"
                  "mpd.service"
                ];
                requires = [ "mpd.service" ];
                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                  Type = "simple";
                  ExecStart = "${upmpdcli}/bin/upmpdcli -c ${configFile}";
                  Restart = "on-failure";
                  User = "upmpdcli";
                  Group = "audio";

                  # Environment for Python plugins
                  Environment = [
                    "PYTHONPATH=${pythonEnv}/${pkgs.python3.sitePackages}"
                    "PATH=${pythonEnv}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin"
                  ];

                  # Security hardening
                  PrivateTmp = true;
                  ProtectSystem = "strict";
                  ProtectHome = true;
                  ReadWritePaths = [
                    "/var/lib/upmpdcli"
                    "/var/cache/upmpdcli"
                    "/var/log" # For logging
                  ];
                };

                enable = localSettings.enable or true;
              };

              # Create necessary directories
              systemd.tmpfiles.rules = [
                "d /var/lib/upmpdcli 0755 upmpdcli audio -"
                "d /var/lib/upmpdcli/media 0755 upmpdcli audio -"
                "d /var/cache/upmpdcli 0755 upmpdcli audio -"
              ];

              # Open firewall ports
              networking.firewall.allowedTCPPorts = mkDefault (
                (if localSettings.upnpPort != 0 then [ localSettings.upnpPort ] else [ ])
                ++ (if localSettings.enableMediaServer then [ localSettings.mediaServerPort ] else [ ])
              );

              # Ensure MPD is configured and enabled
              assertions = [
                {
                  assertion = config.services.mpd.enable or false;
                  message = "upmpdcli requires MPD to be enabled. Please enable MPD service.";
                }
              ];
            };
        };
    };
  };

  # No perMachine configuration needed
  perMachine = _: {
    nixosModule = _: { };
  };
}
