derivation {
  name = "mini-program";
  system = builtins.currentSystem;
  builder = "/bin/sh";
  args = [
    "-c"
    ''
      echo '#include <stdio.h>' > main.c
      echo 'int main(){puts("hi");}' >> main.c
      gcc main.c -o $out
    ''
  ];
  PATH = "/run/current-system/sw/bin"; # so gcc is found
}

