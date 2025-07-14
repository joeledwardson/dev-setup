# home.nix
{ config, pkgs, lib, ... }:

let
in {
  home.packages = with pkgs; [
    ## GPU accelerated programs 
    google-chrome
    brave
    slack
    vlc
    kitty
    ## keyboard configuration apps
    qmk
    via
    ## desktop apps
    copyq
    autokey
    pomodoro-gtk
  ];
}
