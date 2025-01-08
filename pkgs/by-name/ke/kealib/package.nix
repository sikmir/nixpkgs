{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  hdf5,
  gitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kealib";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "ubarsc";
    repo = "kealib";
    tag = "kealib-${finalAttrs.version}";
    hash = "sha256-wisBE/j2zqW2OdSXezM8/UGnVqNxUZtzDMpbCDUgC9U=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ hdf5 ];

  passthru.updateScript = gitUpdater { rev-prefix = "kealib-"; };

  meta = {
    description = "KEALib provides an implementation of the GDAL data model";
    homepage = "http://kealib.org/";
    license = lib.licenses.mit;
    teams = [ lib.teams.geospatial ];
    platforms = lib.platforms.unix;
  };
})
