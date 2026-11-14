{ lib, stdenv, fetchzip, autoPatchelfHook, openssl, xz }:

# Prebuilt codeg-server release (server + web UI), https://docs.codeg.app/getting-started/deployment
# in-app self-update can't write to /nix/store, so updates happen here
stdenv.mkDerivation rec {
  pname = "codeg";
  version = "0.44.0";

  src = fetchzip {
    url = "https://github.com/spacering-net/codeg/releases/download/v${version}/codeg-server-linux-x64.tar.gz";
    hash = "sha256-WhUEQdGY+8WSb1zpkbLD8V6P/bATEoeS3z/tgWLpZNs=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ openssl xz stdenv.cc.cc.lib ];

  # codeg-server finds codeg-mcp next to itself (CODEG_MCP_BIN defaults to the sibling)
  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin codeg-server codeg-cli codeg-mcp codeg-computer-helper
    mkdir -p $out/share/codeg
    cp -r web $out/share/codeg/web
    runHook postInstall
  '';

  meta = {
    description = "Multi-agent coding workspace over ACP, self-hosted server with web UI";
    homepage = "https://docs.codeg.app";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codeg-server";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
