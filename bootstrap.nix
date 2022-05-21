{ pkgs ? import <nixpkgs> { } }:

let
  onix = import ./default.nix { };

  scope = onix.build {
    lock = ./onix-lock.nix;
    overrides = { };
  };
in scope.onix
