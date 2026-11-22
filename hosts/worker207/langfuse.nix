{ pkgs, ... }:

{
  age.secrets.langfuse-client-env = {
    file = ../../secrets/langfuse-client-env.age;
    owner = "claude";
    mode = "0400";
  };

  # Explicit wrapper: ordinary Claude/Codex sessions stay untraced.
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "langfuse-agent";
      runtimeInputs = [ pkgs.git pkgs.coreutils ];
      text = builtins.readFile ../../scripts/langfuse-agent.sh;
    })
  ];
}
