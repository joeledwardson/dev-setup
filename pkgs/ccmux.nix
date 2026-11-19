{ lib, stdenv, fetchurl, autoPatchelfHook }:

# Prebuilt release binary (a Bun single-file executable). Building from source needs Bun.
stdenv.mkDerivation rec {
  pname = "ccmux";
  version = "1.4.6";

  src = fetchurl {
    url = "https://github.com/epilande/ccmux/releases/download/v${version}/ccmux-linux-x64";
    hash = "sha256-pPBnfHI4zcZ5TtY3kXQ2r3ypKPqn5/80EGHElunuPsU=";
  };

  dontUnpack = true;
  # Bun appends the bundled JavaScript to the end of the executable; stripping deletes it.
  dontStrip = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/ccmux
    runHook postInstall
  '';

  meta = {
    description = "tmux picker and sidebar for AI coding agent sessions";
    homepage = "https://github.com/epilande/ccmux";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ccmux";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
