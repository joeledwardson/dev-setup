{ lib, stdenvNoCC, fetchurl }:

# Prebuilt, statically linked release. The local viewer runs only when invoked.
stdenvNoCC.mkDerivation rec {
  pname = "trajectory";
  version = "0.6.3";

  src = fetchurl {
    url = "https://github.com/datadog-labs/trajectory/releases/download/v${version}/trajectory-linux-amd64";
    hash = "sha256-t2B9UfasW+465W4qKNHqhWPaH+g8LsUHMtVon2U6RnE=";
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/trajectory"
    runHook postInstall
  '';

  meta = {
    description = "Local coding-agent session viewer and tracing CLI";
    homepage = "https://github.com/datadog-labs/trajectory";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "trajectory";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
