{ lib, stdenvNoCC, fetchurl }:

# Prebuilt, statically linked release.
let
  version = "1.11.0";
  releases = {
    x86_64-linux = {
      asset = "x64";
      hash = "sha256-Os+ZpFktKmb/3gwpW+gZDlykDOSF12og+xLUcikye5U=";
    };
    aarch64-linux = {
      asset = "arm64";
      hash = "sha256-exv1zXcT+FNcxZKMsXa6BZ1NxppkO0a9PEi7AeYEUnc=";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system}
    or (throw "runwisp ${version} has no prebuilt release for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "runwisp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/runwisp/runwisp/releases/download/v${version}/runwisp-linux-${release.asset}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 runwisp "$out/bin/runwisp"
    runHook postInstall
  '';

  meta = {
    description = "Cron job manager and process supervisor with a web dashboard";
    homepage = "https://runwisp.com";
    license = lib.licenses.gpl3Plus;
    platforms = builtins.attrNames releases;
    mainProgram = "runwisp";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
