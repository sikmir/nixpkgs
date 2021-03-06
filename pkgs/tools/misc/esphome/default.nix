{ lib
, pkgs
, python3
, fetchFromGitHub
, platformio
, esptool
, git
}:

let
  esphome-dashboard = pkgs.callPackage ./dashboard.nix {};
in
python3.pkgs.buildPythonApplication rec {
  pname = "esphome";
  version = "1.19.4";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "029ykjk24h21b0s0gha6kv9pvgallin6marzkb2vfbvr3icsmbz2";
  };

  patches = [
    # fix missing write permissions on src files before modifing them
   ./fix-src-permissions.patch
  ];

  postPatch = ''
    # remove all version pinning (E.g tornado==5.1.1 -> tornado)
    sed -i -e "s/==[0-9.]*//" requirements.txt

    # drop coverage testing
    sed -i '/--cov/d' pytest.ini

    # migrate use of hypothesis internals to be compatible with hypothesis>=5.32.1
    # https://github.com/esphome/issues/issues/2021
    substituteInPlace tests/unit_tests/strategies.py --replace \
      "@st.defines_strategy_with_reusable_values" \
      "@st.defines_strategy(force_reusable_values=True)"
  '';

  # Remove esptool and platformio from requirements
  ESPHOME_USE_SUBPROCESS = "";

  # esphome has optional dependencies it does not declare, they are
  # loaded when certain config blocks are used, like `font`, `image`
  # or `animation`.
  # They have validation functions like:
  # - validate_cryptography_installed
  # - validate_pillow_installed
  propagatedBuildInputs = with python3.pkgs; [
    click
    colorama
    cryptography
    esphome-dashboard
    ifaddr
    paho-mqtt
    pillow
    protobuf
    pyserial
    pyyaml
    tornado
    tzlocal
    voluptuous
  ];

  makeWrapperArgs = [
    # platformio is used in esphomeyaml/platformio_api.py
    # esptool is used in esphomeyaml/__main__.py
    # git is used in esphomeyaml/writer.py
    "--prefix PATH : ${lib.makeBinPath [ platformio esptool git ]}"
    "--set ESPHOME_USE_SUBPROCESS ''"
  ];

  checkInputs = with python3.pkgs; [
    hypothesis
    mock
    pytest-asyncio
    pytest-mock
    pytest-sugar
    pytestCheckHook
  ];

  postCheck = ''
    $out/bin/esphome --help > /dev/null
  '';

  passthru = {
    dashboard = esphome-dashboard;
  };

  meta = with lib; {
    description = "Make creating custom firmwares for ESP32/ESP8266 super easy";
    homepage = "https://esphome.io/";
    license = with licenses; [
      mit # The C++/runtime codebase of the ESPHome project (file extensions .c, .cpp, .h, .hpp, .tcc, .ino)
      gpl3Only # The python codebase and all other parts of this codebase
    ];
    maintainers = with maintainers; [ globin elseym hexa ];
  };
}
