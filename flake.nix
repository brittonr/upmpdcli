{
  description = "UPnP Media Renderer front-end for MPD with Tidal support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Dependencies
        libnpupnp = pkgs.callPackage ./libnpupnp.nix {};
        libupnpp = pkgs.callPackage ./libupnpp.nix { inherit libnpupnp; };

        # Python environment for plugins
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          requests
          tidalapi
          bottle  # For web interface
        ]);

        # Main upmpdcli package
        upmpdcli = pkgs.stdenv.mkDerivation rec {
          pname = "upmpdcli";
          version = "1.9.7";

          src = pkgs.fetchurl {
            url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
            hash = "sha256-exDMNcrpN3xUKro5g9/TnjS03V//ZFEvVP64fmTPhgk=";
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            pythonEnv
            makeWrapper
            meson
            ninja
          ];

          buildInputs = with pkgs; [
            curl
            jsoncpp
            libmpdclient
            libmicrohttpd
            libupnpp
            pythonEnv
          ];

          # Prevent installation to /etc which fails in sandboxed builds
          postPatch = ''
            # Modify the meson.build to install config to share/upmpdcli instead of /etc
            substituteInPlace meson.build \
              --replace-fail "install_dir: '/etc'" "install_dir: get_option('datadir') / 'upmpdcli'"

            # Disable the install script that tries to write to /etc
            substituteInPlace meson.build \
              --replace-fail "meson.add_install_script('tools/installconfig.sh')" "# meson.add_install_script disabled"
          '';

          # Ensure plugins can find Python modules
          postInstall = ''
            # Wrap Python plugin scripts (only executable ones)
            for plugin in $out/share/upmpdcli/cdplugins/*; do
              if [ -d "$plugin" ]; then
                for script in "$plugin"/*.py; do
                  if [ -f "$script" ] && [ -x "$script" ]; then
                    wrapProgram "$script" \
                      --prefix PYTHONPATH : ${pythonEnv}/${pkgs.python3.sitePackages}
                  fi
                done
              fi
            done
          '';

          meta = with pkgs.lib; {
            description = "UPnP Media Renderer front-end for MPD with Tidal support";
            homepage = "https://www.lesbonscomptes.com/upmpdcli/";
            license = licenses.gpl2Plus;
            platforms = platforms.linux;
            maintainers = [];
          };
        };
      in
      {
        packages = {
          inherit libnpupnp libupnpp upmpdcli;
          default = upmpdcli;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkg-config
            libmpdclient
            curl
            jsoncpp
            libmicrohttpd
            pythonEnv
          ];

          shellHook = ''
            echo "upmpdcli development environment"
            echo "To build: nix build"
            echo "To test: nix build .#libnpupnp .#libupnpp .#upmpdcli"
          '';
        };

        # NixOS module (can be imported by other flakes)
        nixosModules.default = import ./nixos-module.nix;
      });
}