{
  # allow nix-shell and nix-env to use unfree packages
  nixpkgs.config = { allowUnfree = true; };

}
