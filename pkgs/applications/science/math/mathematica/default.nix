{
  callPackage,
  config,
  lib,
  cudaPackages,
  cudaSupport ? config.cudaSupport,
  lang ? "en",
  webdoc ? false,
  version ? null,
  /*
    If you wish to completely override the src, use:
    my_mathematica = mathematica.override {
      source = pkgs.requireFile {
        name = "Mathematica_XX.X.X_BNDL_LINUX.sh";
        # Get this hash via a command similar to this:
        # nix-store --query --hash \
        # $(nix store add-path Mathematica_XX.X.X_BNDL_LINUX.sh --name 'Mathematica_XX.X.X_BNDL_LINUX.sh')
        sha256 = "0000000000000000000000000000000000000000000000000000";
        message = ''
          Your override for Mathematica includes a different src for the installer,
          and it is missing.
        '';
        hashMode = "recursive";
      };
    }
  */
  source ? null,
}:

let
  versions = callPackage ./versions.nix { };

  matching-versions = lib.sort (v1: v2: lib.versionOlder v2.version v1.version) (
    lib.filter (
      v: v.lang == lang && (version == null || isMatching v.version version) && matchesDoc v
    ) versions
  );

  found-version =
    if matching-versions == [ ] then
      throw (
        "No registered Mathematica version found to match"
        + " version=${toString version} and language=${lang},"
        + " ${if webdoc then "using web documentation" else "and with local documentation"}"
      )
    else
      lib.head matching-versions;

  isMatching =
    v1: v2:
    let
      as = lib.splitVersion v1;
      bs = lib.splitVersion v2;
      n = lib.min (lib.length as) (lib.length bs);
      sublist = l: lib.sublist 0 n l;
    in
    lib.compareLists lib.compare (sublist as) (sublist bs) == 0;

  matchesDoc = v: (builtins.match ".*[0-9]_LIN(UX)?.sh" v.src.name != null) == webdoc;

in

callPackage ./generic.nix {
  inherit cudaSupport cudaPackages;
  inherit (found-version) version lang;
  src = if source == null then found-version.src else source;
  name = (
    "mathematica"
    + lib.optionalString cudaSupport "-cuda"
    + "-${found-version.version}"
    + lib.optionalString (lang != "en") "-${lang}"
  );
  meta = with lib; {
    description = "Wolfram Mathematica computational software system";
    homepage = "https://www.wolfram.com/mathematica/";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [
      herberteuler
      rafaelrc
    ];
    platforms = [ "x86_64-linux" ];
  };
}
