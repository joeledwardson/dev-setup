# SigNoz's collector is a custom OpenTelemetry Collector distribution. Besides
# its ClickHouse exporters, this binary owns SigNoz's telemetry schema
# migrations, so the stock contrib collector cannot replace it server-side.
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation (finalAttrs: {
  pname = "signoz-otel-collector";
  version = "0.144.9";

  src = fetchurl {
    url = "https://github.com/SigNoz/signoz-otel-collector/releases/download/v${finalAttrs.version}/signoz-otel-collector_linux_amd64.tar.gz";
    hash = "sha256-KEu/q9GVQX12rI1kD00SnW7P74tKRteA4Olk68G4MXs=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  sourceRoot = "signoz-otel-collector_linux_amd64";

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/signoz-otel-collector $out/bin/signoz-otel-collector
    runHook postInstall
  '';

  meta = {
    description = "SigNoz OpenTelemetry Collector distribution";
    homepage = "https://github.com/SigNoz/signoz-otel-collector";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "signoz-otel-collector";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
