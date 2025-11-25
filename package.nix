# Alternative minimal package definition for upmpdcli
# This can be used if the main module build fails

{
  lib,
  stdenv,
  fetchurl,
  autoreconfHook,
  pkg-config,
  libupnp,
  libmpdclient,
  curl,
  expat,
  jsoncpp,
  libmicrohttpd,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "upmpdcli";
  version = "1.9.7";

  # To get the hash, run:
  # nix-prefetch-url --unpack https://framagit.org/medoc92/upmpdcli/-/archive/upmpdcli-1.9.7/upmpdcli-upmpdcli-1.9.7.tar.gz
  src = fetchurl {
    url = "https://framagit.org/medoc92/upmpdcli/-/archive/upmpdcli-${version}/upmpdcli-upmpdcli-${version}.tar.gz";
    hash = "sha256-PLACEHOLDER"; # Replace with actual hash
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    libupnp
    libmpdclient
    curl
    expat
    jsoncpp
    libmicrohttpd
    python3
    python3.pkgs.requests
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--enable-upnpav"
    "--enable-openhome"
  ];

  # The Tidal plugin requires python-tidal which needs to be packaged separately
  # For now, basic UPnP functionality will work without it

  postInstall = ''
    # Create directories for configuration
    mkdir -p $out/etc/upmpdcli

    # If config file exists, install it as example
    if [ -f src/upmpdcli.conf ]; then
      cp src/upmpdcli.conf $out/etc/upmpdcli/upmpdcli.conf.example
    fi
  '';

  meta = with lib; {
    description = "UPnP Media Renderer front-end for MPD";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/";
    license = licenses.gpl2Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
