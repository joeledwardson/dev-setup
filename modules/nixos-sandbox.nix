# Sandbox machine marker — imported by headless/remote boxes (pi-box, streaming-server).
# Sets IS_SANDBOX_MACHINE so zshrc can show the sandbox welcome + yolo-claude alias.
# Sets GIT_* env vars so claude-bot commits are attributed correctly regardless of
# whatever gitconfig is present on the machine.
{ pkgs, ... }: {
  environment.variables = {
    IS_SANDBOX_MACHINE   = "1";
    GIT_AUTHOR_NAME      = "joels-claude-bot";
    GIT_AUTHOR_EMAIL     = "joel.edwardson1+claudebot@gmail.com";
    GIT_COMMITTER_NAME   = "joels-claude-bot";
    GIT_COMMITTER_EMAIL  = "joel.edwardson1+claudebot@gmail.com";
  };

  # Clone dev-setup into each user's home on first boot once network is up.
  systemd.services.bootstrap-devsetup-jollof = {
    description = "Clone dev-setup into jollof home";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    serviceConfig = {
      Type            = "oneshot";
      User            = "jollof";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -d /home/jollof/dev-setup ]; then
        ${pkgs.git}/bin/git clone https://github.com/joeledwardson/dev-setup.git /home/jollof/dev-setup
      fi
    '';
  };

  systemd.services.bootstrap-devsetup-claude = {
    description = "Clone dev-setup into claude home";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    serviceConfig = {
      Type            = "oneshot";
      User            = "claude";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -d /home/claude/dev-setup ]; then
        ${pkgs.git}/bin/git clone https://github.com/joeledwardson/dev-setup.git /home/claude/dev-setup
      fi
    '';
  };
}
