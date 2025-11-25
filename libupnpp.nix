{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  expat,
  curl,
  libnpupnp,
}:

stdenv.mkDerivation rec {
  pname = "libupnpp";
  version = "1.0.3";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
    hash = "sha256-0lx8z6hqpcc5bpqd787kgwkagb4kk2c5igjnys4v5bsv4x6p7sl9";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    expat
    curl
    libnpupnp
  ];

  meta = with lib; {
    description = "Application-oriented C++ layer over the libnpupnp base UPnP library";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/libupnpp-refdoc/libupnpp-ctl.html";
    license = licenses.lgpl21Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
