# SigNoz — not in nixpkgs. Upstream ships a prebuilt Go binary plus the built
# web frontend, so this fetches that release artifact rather than building the
# Go server and the React bundle from source.
#
# "community" is the Apache-2.0 edition; the plain `signoz_linux_amd64` asset is
# the enterprise build.
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation (finalAttrs: {
  pname = "signoz";
  version = "0.140.0";

  src = fetchurl {
    url = "https://github.com/SigNoz/signoz/releases/download/v${finalAttrs.version}/signoz-community_linux_amd64.tar.gz";
    hash = "sha256-yVIoImBYk8D34i1955PY1q8hCLI17YmCkIZ+24V5TMs=";
  };

  # Go binary, but patchelf it anyway in case it is dynamically linked against
  # the build host's glibc.
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  sourceRoot = "signoz-community_linux_amd64";

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/signoz $out/bin/signoz

    # The server reads these at runtime; their locations are named in the config
    # written by the NixOS module.
    mkdir -p $out/share/signoz
    cp -r web templates conf $out/share/signoz/

    runHook postInstall
  '';

  meta = {
    description = "OpenTelemetry-native logs, metrics and traces in a single pane";
    homepage = "https://signoz.io/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "signoz";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
