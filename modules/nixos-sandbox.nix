# Sandbox machine marker — imported by headless/remote boxes (pi-box, streaming-server).
# Sets IS_SANDBOX_MACHINE so zshrc can show the sandbox welcome + yolo-claude alias.
# Sets GIT_* env vars so claude-bot commits are attributed correctly regardless of
# whatever gitconfig is present on the machine.
{ pkgs, ... }: {
  environment.variables = {
    IS_SANDBOX_MACHINE = "1";
    GIT_AUTHOR_NAME = "joels-claude-bot";
    GIT_AUTHOR_EMAIL = "joel.edwardson1+claudebot@gmail.com";
    GIT_COMMITTER_NAME = "joels-claude-bot";
    GIT_COMMITTER_EMAIL = "joel.edwardson1+claudebot@gmail.com";
  };

}
