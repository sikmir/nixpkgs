{ fetchurl, lib, stdenv, makeDesktopItem, makeWrapper, unzip, jdk, copyDesktopItems
, exiftool, gpsbabel, gnuplot, povray }:
let
  # See https://activityworkshop.net/software/gpsprune/dependencies.html
  j3d = {
    x86_64-linux = fetchurl {
      url = "http://download.java.net/media/java3d/builds/release/1.5.2/j3d-1_5_2-linux-amd64.zip";
      sha256 = "sha256-kG6EdH1Jk98It2VXa4rA/VgKEGL+G8yhc/8NBglnsXU=";
    };
    x86_64-darwin = fetchurl {
      url = "http://download.java.net/media/java3d/builds/release/1.5.2/j3d-1_5_2-macosx.zip";
      sha256 = "sha256-kG6EdH1Jk98It2VXa4rA/VgKEGL+G8yhc/8NBgl23XU=";
    };
  }.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  pname = "gpsprune";
  version = "21.3";

  src = fetchurl {
    url = "https://activityworkshop.net/software/gpsprune/gpsprune_${version}_source.tar.bz2";
    sha256 = "sha256-twqB4pReaf7VwTMDHHwwpJrCZVTta7OGwUmkizQ2Mg4=";
  };

  nativeBuildInputs = [ makeWrapper copyDesktopItems unzip ];
  buildInputs = [ jdk ];

  desktopItems = [
    (makeDesktopItem {
      name = "gpsprune";
      exec = "gpsprune";
      icon = "gpsprune";
      desktopName = "GpsPrune";
      genericName = "GPS Data Editor";
      comment = meta.description;
      categories = [ "Education" "Geoscience" ];
    })
  ];

  postPatch = ''
    unzip -j ${j3d} */j3d-jre.zip
    unzip j3d-jre.zip
  '';

  buildPhase = ''
    runHook preBuild

    CLASSPATH=lib/ext/* sh ./build.sh

    runHook postBuild
  '';

  runtimeDeps = [ exiftool gpsbabel gnuplot povray ];

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/gpsprune_${version}.jar $out/share/java/gpsprune.jar
    install -Dm644 tim/prune/gui/images/window_icon_64.png $out/share/pixmaps/gpsprune.png

    mv lib $out/share/lib

    makeWrapper ${jdk}/bin/java $out/bin/gpsprune \
      --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      --prefix LD_LIBRARY_PATH : "$out/share/lib/amd64" \
      --add-flags "-cp $out/share/java/gpsprune.jar:$out/share/lib/ext/*" \
      --add-flags "tim.prune.GpsPrune"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Application for viewing, editing and converting GPS coordinate data";
    homepage = "https://activityworkshop.net/software/gpsprune/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    changelog = "https://activityworkshop.net/software/gpsprune/whats_new.html";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ rycee ];
    platforms = platforms.unix;
  };
}
