{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  expat,
  curl,
}:

stdenv.mkDerivation rec {
  pname = "libnpupnp";
  version = "6.2.3";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/${pname}-${version}.tar.gz";
    hash = "sha256-1s8jjwjm5jk1call5qjvcc4w1a0kfmdacxm81db8b5vqx2h3sxkw";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    expat
    curl
  ];

  meta = with lib; {
    description = "A C++ base UPnP library, derived from Portable UPnP, a.k.a libupnp";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/npupnp-doc/libnpupnp.html";
    license = licenses.bsd3;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
