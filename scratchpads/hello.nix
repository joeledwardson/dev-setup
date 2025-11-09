derivation {
  name = "hello-text";
  builder = "/bin/sh";
  system = builtins.currentSystem;
  args = [ "-c" "echo 'Hello world!' > $out" ];
}

