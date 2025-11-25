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
            # Wrap Python plugin scripts
            for plugin in $out/share/upmpdcli/cdplugins/*; do
              if [ -d "$plugin" ]; then
                for script in "$plugin"/*.py; do
                  if [ -f "$script" ]; then
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