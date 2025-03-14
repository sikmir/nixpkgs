{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
  jre_headless,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "purpur";
  version = "1.21.3r2358";

  src = fetchurl {
    url = "https://api.purpurmc.org/v2/purpur/${
      builtins.replaceStrings [ "r" ] [ "/" ] version
    }/download";
    sha256 = "sha256-RFrP7q1jgKUztF518HA6Jmj1qXa51l1HegMH1wMr5W4=";
  };

  nativeBuildInputs = [ makeWrapper ];

  preferLocalBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/minecraft
    cp -v $src $out/lib/minecraft/server.jar

    makeWrapper ${jre_headless}/bin/java $out/bin/minecraft-server \
      --add-flags "-jar $out/lib/minecraft/server.jar nogui"
  '';

  dontUnpack = true;

  passthru = {
    tests = { inherit (nixosTests) minecraft-server; };
  };

  meta = with lib; {
    description = "Drop-in replacement for Minecraft Paper servers";
    longDescription = ''
      Purpur is a drop-in replacement for Minecraft Paper servers designed for configurability, new fun and exciting
      gameplay features, and performance built on top of Airplane.
    '';
    homepage = "https://purpurmc.org/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "minecraft-server";
  };
}
