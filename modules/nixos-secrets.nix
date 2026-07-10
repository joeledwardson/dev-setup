{ owner }:
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
in {
  age.secrets = {
    llm-gemini-key = mkSecret ../secrets/llm-gemini-key.age;
    hermes-env = mkSecret ../secrets/hermes-env.age;
    ntfy-token = mkSecret ../secrets/ntfy-token.age;
    sparkyfitness-secrets = mkSecret ../secrets/sparkyfitness-secrets.age;
    sparkyfitness-manual = mkSecret ../secrets/sparkyfitness-manual.age;
  };
}
