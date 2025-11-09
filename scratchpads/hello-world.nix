let pkgs = import <nixpkgs> { };
in derivation {
  name = "hello-world";
  system = builtins.currentSystem;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    ''
      export PATH="$PATH:${pkgs.coreutils}/bin"
      echo '#!${pkgs.bash}/bin/bash' > $out
      echo 'echo "Hello, World!"' >> $out
      chmod +x $out
    ''
  ];
}
