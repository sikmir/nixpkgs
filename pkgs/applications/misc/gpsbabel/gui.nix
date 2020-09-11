{ stdenv, mkDerivation, substituteAll, qmake, qttools, qtwebkit, qttranslations, gpsbabel }:

mkDerivation {
  pname = "gpsbabel-gui";

  inherit (gpsbabel) src version;

  sourceRoot = "source/gui";

  patches = [
    (substituteAll {
      src = ./fix-translations-path.patch;
      inherit qttranslations;
    })
    (substituteAll {
      src = ./fix-gpsbabel-path.patch;
      inherit gpsbabel;
    })
    ./dont-check-update.patch
  ];

  patchFlags = [ "-p2" ];

  nativeBuildInputs = [ qmake qttools ];
  buildInputs = [ qtwebkit ];

  preConfigure = ''
    lrelease *.ts coretool/*.ts
  '';

  postInstall = ''
    install -Dm755 objects/gpsbabelfe -t $out/bin
    install -Dm644 gpsbabel.desktop -t $out/share/applications
    install -Dm644 images/appicon.png $out/share/icons/hicolor/512x512/apps/gpsbabel.png
    install -Dm644 *.qm coretool/*.qm -t $out/share/gpsbabel/translations
  '';

  meta = with stdenv.lib; {
    description = "Qt-based GUI for gpsbabel";
    homepage = "http://www.gpsbabel.org/";
    license = licenses.gpl2;
    maintainers = with maintainers; [ sikmir ];
    platforms = with platforms; linux;
  };
}
