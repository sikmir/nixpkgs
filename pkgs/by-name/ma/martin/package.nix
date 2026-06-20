{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  buildNpmPackage,
  rustPlatform,
  pkg-config,
  curl,
  libuv,
  libz,
  openssl,
  postgresql,
  postgresqlTestHook,
  nix-update-script,
}:

let
  # check package.metadata.mln in https://github.com/maplibre/maplibre-native-rs/blob/main/Cargo.toml
  mlnRelease = "core-cc8aa6fe74564180e2eed277dabd2043907c7fd8";
  mlnHeaders = fetchurl {
    url = "https://github.com/maplibre/maplibre-native/releases/download/${mlnRelease}/maplibre-native-headers.tar.gz";
    hash = "sha256-YqpJ0M5obJbBJlGD/VVcLx65zUlUQ5GcmR5K7y0hXTk=";
  };
  mlnLibrary = fetchurl (
    let
      sources = {
        aarch64-linux = {
          url = "https://github.com/maplibre/maplibre-native/releases/download/${mlnRelease}/libmaplibre-native-core-amalgam-linux-arm64-vulkan.a";
          hash = "sha256-PHFNdzcG3+kngZmziMccCTnwBUbtsS2RAUNkTyNYXmc";
        };
        x86_64-linux = {
          url = "https://github.com/maplibre/maplibre-native/releases/download/${mlnRelease}/libmaplibre-native-core-amalgam-linux-x64-vulkan.a";
          hash = "sha256-T9H7NiXHv+hbMgOd5QetQzxjIX1Ufn6gNmBJJ/7Ha50=";
        };
      };
    in
    sources.${stdenv.hostPlatform.system}
    // {
      downloadToTemp = true;
      recursiveHash = true;
      postFetch = ''
        install -Dm644 $downloadedFile $out/libmbgl-core-amalgam.a
      '';
    }
  );
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "martin";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "maplibre";
    repo = "martin";
    tag = "martin-v${finalAttrs.version}";
    hash = "sha256-saqEcCuRz8Jlu8HTf0cjmNGDATasImfuFx1dbHHoARQ=";
  };

  patches = [ ./dont-build-webui.patch ];

  cargoHash = "sha256-JC6qIoyIQYQVBA43WwPXe5VW2qJOqWga3beq5t7I5rE=";

  webui = buildNpmPackage {
    pname = "martin-ui";
    inherit (finalAttrs) version doCheck;

    src = "${finalAttrs.src}/martin/martin-ui";

    postPatch = ''
      substituteInPlace src/App.tsx \
        --replace-warn "./assets" "$src/src/assets"
      ln -sf ${finalAttrs.src}/demo/frontend/public/favicon.ico public/_/assets/favicon.ico
    '';

    npmDepsHash = "sha256-e4LVUGUxwoiOJHhKn+4GQWbA5qbDtaak9FHMrmW+8Ts=";

    buildPhase = ''
      runHook preBuild
      npm exec vite build
      runHook postBuild
    '';

    checkPhase = ''
      runHook preCheck
      npm run test
      runHook postCheck
    '';

    installPhase = ''
      cp -r dist $out
    '';
  };

  preBuild = ''
    rm -rf martin/martin-ui/dist
    cp -r ${finalAttrs.webui} martin/martin-ui/dist
  '';

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    curl
    libuv
    libz
    openssl
  ];

  nativeCheckInputs = [
    postgresql
    postgresqlTestHook
  ];

  # Tests are time-consuming and moved to passthru.tests.withCheck.
  doCheck = false;

  checkFlags = [
    # Requires docker
    "--skip=test_nonexistent_tables_functions_generate_warning"
  ];

  passthru.tests = lib.optionalAttrs (!postgresqlTestHook.meta.broken) {
    withCheck = finalAttrs.finalPackage.overrideAttrs {
      doCheck = true;
    };
  };

  env = {
    MLN_PRECOMPILE = 1;
    MLN_CORE_LIBRARY_PATH = "${mlnLibrary}/libmbgl-core-amalgam.a";
    MLN_CORE_LIBRARY_HEADERS_PATH = "${mlnHeaders}";
  };

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex=martin-v(.*)"
      "--subpackage=webui"
    ];
  };

  meta = {
    description = "Blazing fast and lightweight PostGIS vector tiles server";
    homepage = "https://martin.maplibre.org/";
    license = with lib.licenses; [
      mit # or
      asl20
    ];
    teams = [ lib.teams.geospatial ];
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode # maplibre-native
      fromSource
    ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
})
