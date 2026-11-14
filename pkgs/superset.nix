{ lib, appimageTools, fetchurl }:

# Upstream ships only an AppImage/.deb for Linux; wrapType2 runs it in an FHS
# sandbox so it works on NixOS without `nix run nixpkgs#appimage-run`.
let
  pname = "superset";
  version = "2.0.6";

  src = fetchurl {
    url = "https://github.com/superset-sh/superset/releases/download/desktop-v${version}/superset-${version}-x86_64.AppImage";
    hash = "sha256-l5b9CQDklEeGojfCrsjAsICv602XMcp/d2MnmqKziV4=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Launcher entry lives in applications/superset.desktop; only ship the icons.
  extraInstallCommands = ''
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Desktop app for running parallel coding agents";
    homepage = "https://superset.sh";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
