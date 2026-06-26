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
    ntfy-token = mkSecret ../secrets/ntfy-token.age;
    usda = mkSecret ../secrets/usda.age;
    fatsecret-client-id = mkSecret ../secrets/fatsecret-client-id.age;
    fatsecret-client-secret = mkSecret ../secrets/fatsecret-client-secret.age;
    sparkyfitness-secrets = mkSecret ../secrets/sparkyfitness-secrets.age;
  };
}
