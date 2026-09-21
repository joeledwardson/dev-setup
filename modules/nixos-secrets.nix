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
    llm-gemini-key = mkSecret ../secrets/llm-gemini-key.age;
    litellm-env = mkSecret ../secrets/litellm-env.age;
    hermes-env = mkSecret ../secrets/hermes-env.age;
    ntfy-token = mkSecret ../secrets/ntfy-token.age;
    sparkyfitness-secrets = mkSecret ../secrets/sparkyfitness-secrets.age;
    sparkyfitness-manual = mkSecret ../secrets/sparkyfitness-manual.age;
    sandbox-tailscale-authkey = mkSecret ../secrets/sandbox-tailscale-authkey.age;
    sandbox-github-token = mkSecret ../secrets/sandbox-github-token.age;
    sandbox-gitlab-token = mkSecret ../secrets/sandbox-gitlab-token.age;
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
