{ platform, ocaml-version }:

let
  # pkg_unscoped = {
  #   "lib" = paths.lib { prefix = "$out"; };
  #   "stublibs" = paths.stublibs { prefix = "$out"; };
  #   "toplevel" = paths.toplevel { prefix = "$out"; };
  #   "bin" = paths.bin { prefix = "$out"; };
  #   "sbin" = paths.sbin { prefix = "$out"; };
  #   "share" = paths.share { prefix = "$out"; };
  #   "etc" = paths.etc { prefix = "$out"; };
  #   "doc" = paths.doc { prefix = "$out"; };
  #   "man" = paths.man { prefix = "$out"; };

  #   "build-id" = "$out";
  #   "build" = ".";
  #   "installed" = false;
  #   "name" = self.pname;

  #   "opamfile" = (paths.lib {
  #     prefix = "$out";
  #     pkg-name = self.pname;
  #   }) + "/opam";

  #   "switch" = "$out";
  #   "prefix" = "$out";
  #   "version" = self.version;
  #   "pinned" = self.version == "dev";
  #   "dev" = self.version == "dev";
  # };

  # pkg-vars = pkg: {
  #   "lib" = paths.lib { prefix = pkg; };
  #   "stublibs" = paths.stublibs { prefix = pkg; };
  #   "toplevel" = paths.toplevel { prefix = pkg; };
  #   "bin" = paths.bin { prefix = pkg; };
  #   "sbin" = paths.sbin { prefix = pkg; };
  #   "share" = paths.share { prefix = pkg; };
  #   "etc" = paths.etc { prefix = pkg; };
  #   "doc" = paths.doc { prefix = pkg; };
  #   "man" = paths.man { prefix = pkg; };

  #   "build-id" = builtins.toString pkg;
  #   "installed" = false;
  #   "name" = pkg.pname;

  #   "opamfile" = (paths.lib {
  #     prefix = pkg;
  #     pkg-name = pkg.pname;
  #   }) + "/opam";

  #   "version" = pkg.version;
  #   "pinned" = pkg.version == "dev";
  #   "dev" = pkg.version == "dev";
  # };

  paths = import ./paths.nix { inherit ocaml-version; };

  global = {
    opam-version = "2.0";
    root = "/tmp/onix-opam-root";
    jobs = "$NIX_BUILD_CORES";
    make = "make";

    os-distribution = "nixos";
    os-family = "nixos";
    os-version = "unknown";

    arch = platform.uname.processor;

    os = if platform.isDarwin then
      "macos"
    else if platform.isLinux then
      "linux"
    else
      throw "${platform.uname.system} not supported";
  };

  resolve-global = full-var:
    let
      v = (builtins.trace "resolving global: ${builtins.toJSON full-var}"
        full-var).var;
    in if builtins.hasAttr v global then global.${v} else null;

  # full-var = { var : string; scope : "global" | "self" | "package"; pkg-name : string; }
  resolve-pkg = { build-dir, self, pkgs, ocaml-version }:
    full-var:
    let
      v = full-var.var;
      # g=global, i=installed, m=missing
      scope = if full-var.scope == "global" then {
        tag = "g";
      } else if full-var.scope == "self" then {
        tag = "i";
        pkg = self;
      } else if full-var.scope == "package" then
        if builtins.hasAttr full-var.pkg-name pkgs then {
          tag = "i";
          pkg = pkgs.${full-var.pkg-name};
        } else {
          tag = "m";
          pkg.name = full-var.pkg-name;
        }
      else
        throw "invalid variable scope in ${builtins.toJSON full-var}";

      # name
    in if scope.tag == "g" && v == "name" then
      self.name
    else if scope.tag == "i" && v == "name" then
      scope.pkg.name
    else if scope.tag == "m" && v == "name" then
      scope.pkg.name
      # version
    else if scope.tag == "g" && v == "version" then
      self.version
    else if scope.tag == "i" && v == "version" then
      scope.pkg.version
      # pinned, dev
    else if scope.tag == "g" && (v == "pinned" || v == "dev") then
      self.version == "dev"
    else if scope.tag == "i" && (v == "pinned" || v == "dev") then
      scope.pkg.version == "dev"
      # opamfile
    else if scope.tag == "g" && v == "opamfile" then
      self.opamfile
    else if scope.tag == "i" && v == "opamfile" then
      scope.pkg.opamfile
      # installed/enable
    else if scope.tag == "g" && v == "installed" then
      false # not yet
    else if scope.tag == "i" && v == "installed" then
      true
    else if scope.tag == "m" && v == "installed" then
      false
    else if scope.tag == "i" && v == "enable" then
      "enable"
    else if scope.tag == "m" && v == "enable" then
      "disable"
      # build info
    else if scope.tag == "g" && v == "build" then
      build-dir
    else if scope.tag == "g" && v == "build-id" then
      self.prefix
    else if scope.tag == "g" && v == "depends" then
      null # TODO

      # paths
    else if scope.tag == "g" && (v == "switch" || v == "prefix") then
      self.prefix
    else if scope.tag == "i" && (v == "switch" || v == "prefix") then
      scope.pkg.prefix

    else if scope.tag == "g" && v == "lib" then
      paths.lib { prefix = self.prefix; }
    else if scope.tag == "i" && v == "lib" then
      paths.lib {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }
    else if scope.tag == "g" && v == "toplevel" then
      paths.toplevel { prefix = self.prefix; }
    else if scope.tag == "i" && v == "toplevel" then
      paths.toplevel {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }
    else if scope.tag == "g" && v == "stublibs" then
      paths.stublibs { prefix = self.prefix; }
    else if scope.tag == "i" && v == "stublibs" then
      paths.stublibs {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "bin" then
      paths.bin { prefix = self.prefix; }
    else if scope.tag == "i" && v == "bin" then
      paths.bin {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "sbin" then
      paths.sbin { prefix = self.prefix; }
    else if scope.tag == "i" && v == "sbin" then
      paths.sbin {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "share" then
      paths.share { prefix = self.prefix; }
    else if scope.tag == "i" && v == "share" then
      paths.share {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "doc" then
      paths.doc { prefix = self.prefix; }
    else if scope.tag == "i" && v == "doc" then
      paths.doc {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "etc" then
      paths.etc { prefix = self.prefix; }
    else if scope.tag == "i" && v == "etc" then
      paths.etc {
        prefix = scope.pkg.prefix;
        pkg-name = scope.pkg.name;
      }

    else if scope.tag == "g" && v == "man" then
      paths.man { prefix = self.prefix; }
    else if scope.tag == "i" && v == "man" then
      paths.man { prefix = scope.pkg.prefix; }

    else if (scope.tag == "i" || scope.tag == "m") && (v == "preinstalled" || v
      == "native" || v == "native-tools" || v == "native-dynlink")
    && scope.pkg.name == "ocaml" then
      true

    else if scope.tag == "g" && v == "sys-ocaml-version" then
      ocaml-version
    else
      null;

  resolve = { build-dir, self, pkgs, ocaml-version }@resolve-pkg-args:
    full-var:
    let
      g = resolve-global
        (builtins.trace "resolve: ${builtins.toJSON full-var}" full-var);
    in if !(builtins.isNull g) then
      g
    else
      let
        resolved = resolve-pkg resolve-pkg-args full-var;
        # Attempt to use the fallback values, if any.
      in if builtins.isBool resolved then
        if resolved && builtins.hasAttr "val-if-true" full-var then
          full-var.val-if-true
        else if !resolved && builtins.hasAttr "val-if-false" full-var then
          full-var.val-if-false
        else
          resolved
      else
        resolved;

in { inherit resolve-global resolve-pkg resolve; }
