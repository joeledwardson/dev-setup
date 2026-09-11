{ lib, buildGoModule, fetchFromGitHub, olm, pkg-config }:

buildGoModule rec {
  pname = "mautrix-imessage";
  version = "0-unstable-2026-05-14";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "imessage";
    rev = "300ba6d0e5566d1f841d42ee1555779a9b6fa4be";
    hash = "sha256-qKSb4/kktqNHyOKOOLDrAqV+GZ5StU3lGUc3/90CE+c=";
  };

  vendorHash = "sha256-xTzxL4pk6tmWcEhd0bbdwP70hEqNDjB/xahLWY5nRKQ=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ olm ];
  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Commit=${src.rev}"
  ];

  meta = {
    description = "Matrix-iMessage puppeting bridge";
    homepage = "https://github.com/mautrix/imessage";
    license = lib.licenses.agpl3Only;
    mainProgram = "mautrix-imessage";
    platforms = lib.platforms.darwin;
  };
}
