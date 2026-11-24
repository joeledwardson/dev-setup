{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libxkbcommon,
}:

rustPlatform.buildRustPackage rec {
  pname = "xa11y";
  version = "0.16.1";

  src = fetchFromGitHub {
    owner = "xa11y";
    repo = "xa11y";
    rev = "v${version}";
    hash = "sha256-IKGk7mhDIb6nDssHnYqwzx+dZ7XzIHPS9VBfCA0TGxw=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";
  cargoBuildFlags = [
    "-p"
    "xa11y"
  ];
  cargoTestFlags = [
    "-p"
    "xa11y"
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxkbcommon ];

  meta = {
    description = "Accessibility-tree driven desktop automation";
    homepage = "https://xa11y.dev";
    license = lib.licenses.mit;
    mainProgram = "xa11y";
    platforms = lib.platforms.linux;
  };
}
