{ pkgs ? import <nixpkgs> { }, onix ? import ../../. { inherit pkgs; } }:

let

  inherit (pkgs.lib.lists) optional optionals;
  inherit (builtins)
    filter trace hasAttr getAttr setAttr attrNames attrValues mapAttrs concatMap
    pathExists foldl';

  evalDepFlag = version: depFlag:
    let isRoot = version == "root";
    in if depFlag == true then
      isRoot
    else if depFlag == "deps" then
      !isRoot
    else if depFlag == "all" then
      true
    else if depFlag == false then
      false
    else
      throw "invalid dependency flag value: ${depFlag}";

  processDeps = { withTest, withDoc, withDevSetup }@depFlags:
    builtins.foldl' (acc: dep:
      if acc ? dep.name then
        acc
      else
        let
          depends = dep.depends or [ ];
          buildDepends = dep.buildDepends or [ ];
          testDepends = optionals (evalDepFlag dep.version withTest)
            (dep.testDepends or [ ]);
          docDepends =
            optionals (evalDepFlag dep.version withDoc) (dep.docDepends or [ ]);
          devSetupDepends = optionals (evalDepFlag dep.version withDevSetup)
            (dep.devSetupDepends or [ ]);
          depexts = filter (x: !isNull x) (dep.depexts or [ ]);
          transitive = processDeps depFlags { } (depends ++ buildDepends);
        in acc // transitive // {
          ${dep.name} = {
            depends = map (x: x.name) depends;
            buildDepends = map (x: x.name) buildDepends;
            depexts = map (x: x.name) depexts;
            transitiveDepends = attrValues transitive;
          };
        });

  depFlags = {
    withTest = false;
    withDoc = false;
    withDevSetup = false;
  };
  onixLock = import ../../onix-lock.nix { inherit pkgs; };
  deps = processDeps depFlags { } (builtins.attrValues onixLock);
in pkgs.writeText "transitive-deps.json" (builtins.toJSON deps)
