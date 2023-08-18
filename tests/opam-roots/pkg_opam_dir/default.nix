let onix = import ../../../default.nix { verbosity = "info"; };

in onix.env {
  path = ./.;
  repos = [{
    url = "https://github.com/ocaml/opam-repository.git";
    rev = "9e6ae0a9398cf087ec2b3fbcd62cb6072ccf95ce";
  }];
}
