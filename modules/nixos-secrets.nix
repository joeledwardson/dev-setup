{ owner }: {

  age.secrets.llm-gemini-key = {
    file = ../secrets/llm-gemini-key.age;
    owner = owner;
    group = "users";
    mode = "0440";
  };
  age.secrets.ntfy-token = {
    file = ../secrets/ntfy-token.age;
    owner = owner;
    group = "users";
    mode = "0440";
  };
}
