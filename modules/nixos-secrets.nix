{ owner, enableGcal ? false }:
let
  # Secrets the importing host should expose to its login user. All get the same
  # treatment: owned by `owner`, group `users`, mode 0440 (so the user can read
  # them, e.g. `llm keys set`). Add a name here to declare another.
  mkSecret = filePath: {
    file = filePath;
    inherit owner;
    group = "users";
    mode = "0440";
  };
  baseSecrets = {
    beszel-agent-env = mkSecret ../secrets/beszel-agent-env.age;
    ollama-api-key = mkSecret ../secrets/ollama-api-key.age;
    litellm-env = mkSecret ../secrets/litellm-env.age;
    ntfy-token = mkSecret ../secrets/ntfy-token.age;
    sparkyfitness-secrets = mkSecret ../secrets/sparkyfitness-secrets.age;
    sparkyfitness-manual = mkSecret ../secrets/sparkyfitness-manual.age;
    sparkyfitness-api-key = mkSecret ../secrets/sparkyfitness-api-key.age;
    sandbox-tailscale-authkey = mkSecret ../secrets/sandbox-tailscale-authkey.age;
    sandbox-github-token = mkSecret ../secrets/sandbox-github-token.age;
    sandbox-gitlab-token = mkSecret ../secrets/sandbox-gitlab-token.age;
    travel-logins = mkSecret ../secrets/travel-logins.age;
  };
  gCalSecrets =
    if enableGcal then
      {
        gcal-client-id = mkSecret ../secrets/gcal-client-id.age;
        gcal-client-secret = mkSecret ../secrets/gcal-client-secret.age;
      }
    else
      { };
in
{
  age.secrets = baseSecrets // gCalSecrets;

}
