{ lib, stdenv, fetchFromGitHub, fetchpatch, cmake, makeWrapper } :

stdenv.mkDerivation rec {
  pname = "lzham";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "richgel999";
    repo = "lzham_codec";
    rev = "v${lib.replaceStrings ["."] ["_"] version}_stable1";
    hash = "sha256-DX8c7ivXwohHOl5O63lucKxZMXL4nbwkYewrGhficD8=";
  };

  patches = [
    # Fix building on darwin
    (fetchpatch {
      url = "https://github.com/richgel999/lzham_codec/commit/c1dfe50b723a1410d466e63123ad42a9089b0e8a.patch";
      hash = "sha256-GaklAGsCKHe6qJ+Ry7+iF3f5DI7sDdPJb34CpkcrVXQ=";
    })
  ];

  nativeBuildInputs = [ cmake makeWrapper ];

  postInstall = ''
    install -Dm755 lzhamtest/lzhamtest -t $out/bin
  '';

  postFixup = lib.optionalString stdenv.isDarwin ''
    wrapProgram $out/bin/lzhamtest --prefix DYLD_LIBRARY_PATH : $out/lib
  '';

  meta = with lib; {
    description = "Lossless data compression codec with LZMA-like ratios but 1.5x-8x faster decompression speed";
    mainProgram = "lzhamtest";
    homepage = "https://github.com/richgel999/lzham_codec";
    license = with licenses; [ mit ];
    platforms = platforms.unix;
  };
}
