{ appimageTools, fetchurl }:

# codeg desktop app (Tauri), can attach to a remote codeg-server as a "remote workspace"
# https://docs.codeg.app/guide/workspace#desktop-and-browser
# keep the version in step with pkgs/codeg.nix so the desktop app matches the server it attaches to
let
  pname = "codeg-desktop";
  version = "0.44.0";

  src = fetchurl {
    url = "https://github.com/spacering-net/codeg/releases/download/v${version}/codeg_${version}_amd64.AppImage";
    hash = "sha256-1QqJ/Ug7Q7gKynBEPL/4CmopE+4KNtT8GoOfxdx67HA=";
  };

  extracted = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # launcher entry + icon, the binary is named after pname so point Exec at it
  extraInstallCommands = ''
    install -Dm444 ${extracted}/codeg.desktop $out/share/applications/codeg.desktop
    substituteInPlace $out/share/applications/codeg.desktop --replace-fail 'Exec=codeg' 'Exec=${pname}'
    install -Dm444 ${extracted}/usr/share/icons/hicolor/128x128/apps/codeg.png $out/share/icons/hicolor/128x128/apps/codeg.png
  '';
}
