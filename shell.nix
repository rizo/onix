{ pkgs ? import <nixpkgs> { } }:
let onix = import ./. { inherit pkgs; };
in pkgs.mkShell { inputsFrom = [ onix ]; }
