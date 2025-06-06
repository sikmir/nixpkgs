{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
let
  version = "0.7.9";
in
buildGoModule {
  pname = "lazyjournal";
  inherit version;

  src = fetchFromGitHub {
    owner = "Lifailon";
    repo = "lazyjournal";
    tag = version;
    hash = "sha256-ohMcTu4sK5M11FY2QkJcHnNxx6pmscdH3S2MbWorUVM=";
  };

  vendorHash = "sha256-faMGgTJuD/6CqR+OfGknE0dGdDOSwoODySNcb3kBLv8=";

  ldflags = [
    "-s"
    "-w"
  ];

  # All checks expect a FHS environment with e.g. log files present,
  # which is evidently not possible in a build environment
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "TUI for journalctl, file system logs, as well as Docker and Podman containers";
    homepage = "https://github.com/Lifailon/lazyjournal";
    license = with lib.licenses; [ mit ];
    platforms = with lib.platforms; unix ++ windows;
    maintainers = with lib.maintainers; [ pluiedev ];
    mainProgram = "lazyjournal";
  };
}
