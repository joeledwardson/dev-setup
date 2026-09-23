{ lib, stdenvNoCC, fetchurl, undmg }:

# nixpkgs.bluebubbles is the Linux client; this installs the prebuilt Mac server.
# The Homebrew cask was disabled on 2026-09-01 (Gatekeeper). Install the
# upstream app through nix-darwin instead; first-run approval is still manual.
stdenvNoCC.mkDerivation rec {
  pname = "bluebubbles";
  version = "1.9.9";

  src = fetchurl {
    url = "https://github.com/BlueBubblesApp/bluebubbles-server/releases/download/v${version}/BlueBubbles-${version}-arm64.dmg";
    hash = "sha256-+v1lDIg/UudJSmYl5FJJ8hRNGXN4pNVxQ8z2GYuy6GI=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";
  dontBuild = true;
  # Preserve the prebuilt Electron bundle, including its signatures.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R BlueBubbles.app "$out/Applications/"
    runHook postInstall
  '';

  meta = {
    description = "macOS iMessage server";
    homepage = "https://bluebubbles.app/";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
