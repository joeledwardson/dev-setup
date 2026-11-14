{ lib, stdenv, fetchzip, autoPatchelfHook, zlib }:

# Prebuilt release binary; upstream's flake compiles from source (10+ min).
stdenv.mkDerivation rec {
  pname = "aoe";
  version = "1.23.0";

  src = fetchzip {
    url = "https://github.com/agent-of-empires/agent-of-empires/releases/download/v${version}/aoe-linux-amd64.tar.gz";
    hash = "sha256-MstRafJMBY6CfqC+iAKPTxptiz7QJ6LSqQUcAjaPz5Q=";
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ zlib stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 aoe-linux-amd64 $out/bin/aoe
    runHook postInstall
  '';

  meta = {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://www.agent-of-empires.com";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "aoe";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
