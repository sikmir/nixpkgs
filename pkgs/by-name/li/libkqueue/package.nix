{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation rec {
  pname = "libkqueue";
  version = "2.6.2";

  src = fetchFromGitHub {
    owner = "mheily";
    repo = "libkqueue";
    rev = "v${version}";
    sha256 = "sha256-5Zds9sqHkFldJf3ThTPOiaGKohmFcIzY0ARDA0iswVk=";
  };

  nativeBuildInputs = [ cmake ];

  meta = {
    description = "kqueue(2) compatibility library";
    homepage = "https://github.com/mheily/libkqueue";
    changelog = "https://github.com/mheily/libkqueue/raw/v${version}/ChangeLog";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
  };
}
