let
  pkgs = import <nixpkgs> { };
  repos = [
    { url = "https://github.com/kit-ty-kate/opam-alpha-repository.git"; }
    {
      url = "https://github.com/ocaml/opam-repository.git";
      rev = "fe53d261c062c23d8271f6887702b9bc7459ad2e";
    }
  ];
  paths = map (repo: (builtins.fetchGit repo) // { inherit (repo) url; }) repos;
  path = pkgs.symlinkJoin {
    name = "onix-opam-repos";
    inherit paths;
  };
  json = builtins.toJSON {
    repos = map (x: "${x.url}#${x.rev}") paths;
    path = path;
  };
in path
