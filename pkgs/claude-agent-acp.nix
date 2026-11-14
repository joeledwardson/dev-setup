{ lib, buildNpmPackage, fetchFromGitHub, makeWrapper, claude-code }:

# Copy of nixpkgs' pkgs/by-name/cl/claude-agent-acp, pinned newer: aoe needs >= 0.103.0 and nixpkgs is behind.
# Drop this once nixpkgs-unstable catches up.
buildNpmPackage (finalAttrs: {
  pname = "claude-agent-acp";
  version = "0.107.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "claude-agent-acp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-egXaj0YPZtZE0rklOwjaZljsfbHH6mwJ17mERra8ouE=";
  };

  npmDepsHash = "sha256-AgCxbBMdqXHxnU/xIDNDoklEySgL2sTpHpWYkVOLZn8=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/claude-agent-acp \
      --set-default CLAUDE_CODE_EXECUTABLE ${lib.getExe claude-code}
  '';

  meta = {
    description = "ACP-compatible coding agent powered by the Claude Agent SDK";
    homepage = "https://github.com/agentclientprotocol/claude-agent-acp";
    license = lib.licenses.asl20;
    mainProgram = "claude-agent-acp";
  };
})
