{
  lib,
  stdenv,
  fetchFromGitLab,
  makeDesktopItem,
  cmake,
  boost,
  bzip2,
  ffmpeg_8,
  fftwSinglePrec,
  hdf5,
  muparser,
  netcdf,
  openssl,
  python3,
  qt6Packages,
  imagemagick,
  copyDesktopItems,
  nix-update-script,
  wrapGAppsHook3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ovito";
  version = "3.16.0";

  src = fetchFromGitLab {
    owner = "stuko";
    repo = "ovito";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NN5q+qh84w7myBYiRAsBxDDV/82AmIz8j2yk6JiEHcY=";
    fetchSubmodules = true;
  };

  postPatch = ''
    substituteInPlace src/ovito/core/CMakeLists.txt \
      --replace-fail " IF(OVITO_BUILD_CONDA)" " IF(TRUE)"
    substituteInPlace src/main/CMakeLists.txt \
      --replace-fail 'INCLUDE("''${Ovito_SOURCE_DIR}/cmake/FixupMacBundle.cmake")' ""
  '';

  nativeBuildInputs = [
    cmake
    qt6Packages.wrapQtAppsHook
    wrapGAppsHook3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    imagemagick
    copyDesktopItems
  ];

  buildInputs = [
    boost
    bzip2
    ffmpeg_8
    fftwSinglePrec
    hdf5
    muparser
    netcdf
    openssl
    python3
    qt6Packages.qscintilla
    qt6Packages.qtbase
    qt6Packages.qtsvg
    qt6Packages.qttools
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    # needed to run natively on wayland
    qt6Packages.qtwayland
  ];

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  # manually create a desktop file
  desktopItems = [
    (makeDesktopItem {
      name = "ovito";
      comment = "Open Visualization Tool";
      exec = "ovito";
      icon = "ovito";
      terminal = false;
      startupNotify = false;
      desktopName = "ovito";
      startupWMClass = "Ovito";
      categories = [ "Science" ];
    })
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p $out/share/icons/hicolor/512x512/apps
    magick $src/doc/manual/images/team/ovito_logo_256.png -resize 512x512 $out/share/icons/hicolor/512x512/apps/ovito.png
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p $out/{Applications,bin}
    mv $out/Ovito.app $out/Applications
    ln -s $out/Applications/Ovito.app/Contents/MacOS/ovito $out/bin/ovito

    # Prevent wrapping, otherwise plugins will not be loaded
    chmod -x $out/Applications/Ovito.app/Contents/PlugIns/*.so $out/Applications/Ovito.app/Contents/MacOS/*.dylib
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Scientific visualization and analysis software for atomistic and particle simulation data";
    mainProgram = "ovito";
    homepage = "https://ovito.org";
    changelog = "https://docs.ovito.org/new_features.html";
    license = with lib.licenses; [
      gpl3Only
      mit
    ];
    maintainers = with lib.maintainers; [
      twhitehead
      chn
      chillcicada
    ];
  };
})
