{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "opencode-dashboard";
  version = "0.1.56";

  src = fetchurl {
    url = "https://github.com/Andres77872/opencode-dashboard/releases/download/v${version}/opencode-dashboard_${version}_linux_amd64.tar.gz";
    hash = "sha256-5TF9suNCinoWogAAbOcNJjiLWvtRk16ZtBY6OFcYHQM=";
  };
  sourceRoot = ".";
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode-dashboard "$out/bin/opencode-dashboard"
    runHook postInstall
  '';

  meta = {
    description = "Browse local coding agent sessions, tool calls and token usage";
    homepage = "https://github.com/Andres77872/opencode-dashboard";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "opencode-dashboard";
  };
}
