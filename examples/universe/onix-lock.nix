{ pkgs, self, opam-repo ? builtins.fetchGit {
  url = "https://github.com/ocaml/opam-repository.git";
  rev = "52c72e08d7782967837955f1c50c330a6131721f";
  allRefs = true;
} }:
{
  angstrom =  {
    name = "angstrom";
    version = "0.15.0";
    src = builtins.fetchurl {
      url = "https://github.com/inhabitedtype/angstrom/archive/0.15.0.tar.gz";
    };
    opam = "${opam-repo}/packages/angstrom/angstrom.0.15.0/opam";
    depends = with self; [ bigstringaf dune ocaml ocaml-syntax-shims result ];
    depexts = [ ];
  };
  bap =  {
    name = "bap";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap/bap.2.4.0/opam";
    depends = with self; [ bap-beagle bap-beagle-strings bap-constant-tracker
                           bap-core bap-emacs-goodies bap-microx
                           bap-primus-dictionary bap-primus-powerpc
                           bap-primus-propagate-taint bap-primus-random
                           bap-primus-region bap-primus-support
                           bap-primus-systems bap-primus-taint
                           bap-primus-test bap-primus-x86 bap-run bap-strings
                           bap-taint bap-taint-propagator bap-term-mapper
                           bap-trivial-condition-form bap-warn-unused ocaml ];
    depexts = [ ];
  };
  bap-abi =  {
    name = "bap-abi";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-abi/bap-abi.2.4.0/opam";
    depends = with self; [ bap-std core_kernel ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-analyze =  {
    name = "bap-analyze";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-analyze/bap-analyze.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-std
                           bitvec core_kernel linenoise monads ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-api =  {
    name = "bap-api";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-api/bap-api.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel fileutils ocaml
                           ppx_bap regular ];
    depexts = [ ];
  };
  bap-arm =  {
    name = "bap-arm";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-arm/bap-arm.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-c bap-core-theory
                           bap-knowledge bap-main bap-primus bap-std bitvec
                           bitvec-order core_kernel monads ocaml ogre ppx_bap
                           regular ];
    depexts = [ ];
  };
  bap-beagle =  {
    name = "bap-beagle";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-beagle/bap-beagle.2.4.0/opam";
    depends = with self; [ bap-future bap-microx bap-primus bap-std
                           bap-strings core_kernel monads ocaml ppx_bap
                           regular ];
    depexts = [ ];
  };
  bap-beagle-strings =  {
    name = "bap-beagle-strings";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-beagle-strings/bap-beagle-strings.2.4.0/opam";
    depends = with self; [ bap-beagle bap-std bap-strings core_kernel ocaml
                           ppx_bap regular ];
    depexts = [ ];
  };
  bap-bil =  {
    name = "bap-bil";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-bil/bap-bil.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-future bap-knowledge bap-main
                           bap-std bitvec bitvec-order core_kernel monads
                           ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-build =  {
    name = "bap-build";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-build/bap-build.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ocamlbuild ocamlfind
                           ppx_bap ];
    depexts = [ ];
  };
  bap-bundle =  {
    name = "bap-bundle";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-bundle/bap-bundle.2.4.0/opam";
    depends = with self; [ camlzip core_kernel fileutils oasis ocaml ppx_bap
                           uri ];
    depexts = [ ];
  };
  bap-byteweight =  {
    name = "bap-byteweight";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-byteweight/bap-byteweight.2.4.0/opam";
    depends = with self; [ bap-signatures bap-std camlzip core_kernel ocaml
                           ppx_bap regular uri ];
    depexts = [ ];
  };
  bap-c =  {
    name = "bap-c";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-c/bap-c.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-core-theory bap-knowledge
                           bap-std core_kernel ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-cache =  {
    name = "bap-cache";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-cache/bap-cache.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel fileutils mmap ocaml
                           ppx_bap regular uuidm ];
    depexts = [ ];
  };
  bap-callgraph-collator =  {
    name = "bap-callgraph-collator";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-callgraph-collator/bap-callgraph-collator.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel graphlib ocaml
                           ppx_bap re ];
    depexts = [ ];
  };
  bap-callsites =  {
    name = "bap-callsites";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-callsites/bap-callsites.2.4.0/opam";
    depends = with self; [ bap-std cmdliner oasis ocaml ];
    depexts = [ ];
  };
  bap-constant-tracker =  {
    name = "bap-constant-tracker";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-constant-tracker/bap-constant-tracker.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-core =  {
    name = "bap-core";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-core/bap-core.2.4.0/opam";
    depends = with self; [ bap-abi bap-analyze bap-api bap-arm bap-bil
                           bap-build bap-bundle bap-byteweight bap-c
                           bap-cache bap-callgraph-collator bap-callsites
                           bap-cxxfilt bap-demangle bap-dependencies
                           bap-disassemble bap-dump-symbols bap-elementary
                           bap-flatten bap-frontc bap-frontend
                           bap-glibc-runtime bap-llvm bap-main bap-mc
                           bap-mips bap-objdump bap-optimization bap-patterns
                           bap-plugins bap-powerpc bap-primus bap-primus-lisp
                           bap-print bap-raw bap-recipe bap-recipe-command
                           bap-relation bap-relocatable bap-report bap-riscv
                           bap-specification bap-ssa bap-std
                           bap-stub-resolver bap-symbol-reader bap-systemz
                           bap-thumb bap-toplevel bap-x86 ocaml ];
    depexts = [ ];
  };
  bap-core-theory =  {
    name = "bap-core-theory";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-core-theory/bap-core-theory.2.4.0/opam";
    depends = with self; [ bap-knowledge bitvec bitvec-binprot bitvec-order
                           bitvec-sexp core_kernel oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-cxxfilt =  {
    name = "bap-cxxfilt";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-cxxfilt/bap-cxxfilt.2.4.0/opam";
    depends = with self; [ bap-demangle bap-std conf-binutils ocaml ];
    depexts = [ ];
  };
  bap-demangle =  {
    name = "bap-demangle";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-demangle/bap-demangle.2.4.0/opam";
    depends = with self; [ bap-std cmdliner core_kernel oasis ocaml ];
    depexts = [ ];
  };
  bap-dependencies =  {
    name = "bap-dependencies";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-dependencies/bap-dependencies.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel ocaml ogre ppx_bap
                           regular ];
    depexts = [ ];
  };
  bap-disassemble =  {
    name = "bap-disassemble";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-disassemble/bap-disassemble.2.4.0/opam";
    depends = with self; [ bap-bundle bap-core-theory bap-knowledge bap-main
                           bap-plugins bap-std core_kernel monads ocaml
                           ppx_bap regular ];
    depexts = [ ];
  };
  bap-dump-symbols =  {
    name = "bap-dump-symbols";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-dump-symbols/bap-dump-symbols.2.4.0/opam";
    depends = with self; [ bap-std core_kernel graphlib ocaml ppx_bap regular ];
    depexts = [ ];
  };
  bap-elementary =  {
    name = "bap-elementary";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-elementary/bap-elementary.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-std ocaml ];
    depexts = [ ];
  };
  bap-emacs-dot =  {
    name = "bap-emacs-dot";
    version = "0.1";
    src = builtins.fetchurl {
      url = "https://github.com/ivg/emacs-dot/archive/refs/tags/v0.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-emacs-dot/bap-emacs-dot.0.1/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  bap-emacs-goodies =  {
    name = "bap-emacs-goodies";
    version = "0.1";
    src = null;
    opam = "${opam-repo}/packages/bap-emacs-goodies/bap-emacs-goodies.0.1/opam";
    depends = with self; [ bap-emacs-dot bap-emacs-mode ocaml ];
    depexts = [ ];
  };
  bap-emacs-mode =  {
    name = "bap-emacs-mode";
    version = "0.1";
    src = builtins.fetchurl {
      url = "https://github.com/ivg/bap-mode/archive/refs/tags/v0.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-emacs-mode/bap-emacs-mode.0.1/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  bap-flatten =  {
    name = "bap-flatten";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-flatten/bap-flatten.2.4.0/opam";
    depends = with self; [ bap-std ocaml ];
    depexts = [ ];
  };
  bap-frontc =  {
    name = "bap-frontc";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-frontc/bap-frontc.2.4.0/opam";
    depends = with self; [ bap-c bap-std FrontC ocaml ];
    depexts = [ ];
  };
  bap-frontend =  {
    name = "bap-frontend";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-frontend/bap-frontend.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-std
                           core_kernel oasis ocaml ocamlfind ppx_bap regular ];
    depexts = [ ];
  };
  bap-future =  {
    name = "bap-future";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-future/bap-future.2.4.0/opam";
    depends = with self; [ core_kernel monads oasis ocaml ];
    depexts = [ ];
  };
  bap-glibc-runtime =  {
    name = "bap-glibc-runtime";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-glibc-runtime/bap-glibc-runtime.2.4.0/opam";
    depends = with self; [ bap-abi bap-c bap-main bap-std core_kernel ocaml
                           ogre ];
    depexts = [ ];
  };
  bap-knowledge =  {
    name = "bap-knowledge";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-knowledge/bap-knowledge.2.4.0/opam";
    depends = with self; [ core_kernel monads oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-llvm =  {
    name = "bap-llvm";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-llvm/bap-llvm.2.4.0/opam";
    depends = with self; [ bap-std conf-bap-llvm conf-env-travis core_kernel
                           mmap monads ocaml ogre ppx_bap ];
    depexts = [ pkgs.libxml2 pkgs.ncurses ];
  };
  bap-main =  {
    name = "bap-main";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-main/bap-main.2.4.0/opam";
    depends = with self; [ bap-build bap-future bap-plugins bap-recipe base
                           cmdliner ocaml stdio ];
    depexts = [ ];
  };
  bap-mc =  {
    name = "bap-mc";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-mc/bap-mc.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-plugins
                           bap-std bitvec core_kernel oasis ocaml ogre
                           ppx_bap regular ];
    depexts = [ ];
  };
  bap-microx =  {
    name = "bap-microx";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-microx/bap-microx.2.4.0/opam";
    depends = with self; [ bap-std core_kernel monads ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-mips =  {
    name = "bap-mips";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-mips/bap-mips.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-c bap-core-theory
                           bap-knowledge bap-main bap-std core_kernel ocaml
                           ogre ppx_bap regular zarith ];
    depexts = [ ];
  };
  bap-objdump =  {
    name = "bap-objdump";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-objdump/bap-objdump.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main
                           bap-relation bap-std bitvec bitvec-order
                           bitvec-sexp conf-binutils core_kernel ocaml
                           ppx_bap re ];
    depexts = [ ];
  };
  bap-optimization =  {
    name = "bap-optimization";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-optimization/bap-optimization.2.4.0/opam";
    depends = with self; [ bap-std core_kernel graphlib ocaml ppx_bap regular ];
    depexts = [ ];
  };
  bap-patterns =  {
    name = "bap-patterns";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-patterns/bap-patterns.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-primus
                           bap-relation bap-std bitvec bitvec-binprot
                           bitvec-order bitvec-sexp core_kernel fileutils
                           ocaml ppx_bap uri xmlm zarith ];
    depexts = [ ];
  };
  bap-plugins =  {
    name = "bap-plugins";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-plugins/bap-plugins.2.4.0/opam";
    depends = with self; [ bap-bundle bap-future core_kernel fileutils ocaml
                           ocamlfind ppx_bap uri ];
    depexts = [ ];
  };
  bap-powerpc =  {
    name = "bap-powerpc";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-powerpc/bap-powerpc.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-c bap-core-theory
                           bap-knowledge bap-main bap-std bitvec cmdliner
                           core_kernel monads ocaml ogre ppx_bap regular
                           zarith ];
    depexts = [ ];
  };
  bap-primus =  {
    name = "bap-primus";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus/bap-primus.2.4.0/opam";
    depends = with self; [ bap-abi bap-c bap-core-theory bap-future
                           bap-knowledge bap-std bap-strings bitvec
                           bitvec-binprot core_kernel graphlib monads ocaml
                           parsexp ppx_bap regular uuidm ];
    depexts = [ ];
  };
  bap-primus-dictionary =  {
    name = "bap-primus-dictionary";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-dictionary/bap-primus-dictionary.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-exploring-scheduler =  {
    name = "bap-primus-exploring-scheduler";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-exploring-scheduler/bap-primus-exploring-scheduler.2.4.0/opam";
    depends = with self; [ bap-future bap-primus bap-std monads ocaml ];
    depexts = [ ];
  };
  bap-primus-greedy-scheduler =  {
    name = "bap-primus-greedy-scheduler";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-greedy-scheduler/bap-primus-greedy-scheduler.2.4.0/opam";
    depends = with self; [ bap-primus bap-std monads ocaml ];
    depexts = [ ];
  };
  bap-primus-limit =  {
    name = "bap-primus-limit";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-limit/bap-primus-limit.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-lisp =  {
    name = "bap-primus-lisp";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-lisp/bap-primus-lisp.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-primus
                           bap-std bitvec core_kernel monads ocaml ppx_bap
                           regular ];
    depexts = [ ];
  };
  bap-primus-loader =  {
    name = "bap-primus-loader";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-loader/bap-primus-loader.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-primus bap-std core_kernel
                           ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-primus-mark-visited =  {
    name = "bap-primus-mark-visited";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-mark-visited/bap-primus-mark-visited.2.4.0/opam";
    depends = with self; [ bap-primus bap-primus-track-visited bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-powerpc =  {
    name = "bap-primus-powerpc";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-powerpc/bap-primus-powerpc.2.4.0/opam";
    depends = with self; [ bap-primus bap-std core_kernel ocaml ];
    depexts = [ ];
  };
  bap-primus-print =  {
    name = "bap-primus-print";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-print/bap-primus-print.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-future bap-knowledge
                           bap-primus bap-std bare core_kernel monads ocaml
                           ppx_bap ];
    depexts = [ ];
  };
  bap-primus-promiscuous =  {
    name = "bap-primus-promiscuous";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-promiscuous/bap-primus-promiscuous.2.4.0/opam";
    depends = with self; [ bap-primus bap-std monads ocaml ];
    depexts = [ ];
  };
  bap-primus-propagate-taint =  {
    name = "bap-primus-propagate-taint";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-propagate-taint/bap-primus-propagate-taint.2.4.0/opam";
    depends = with self; [ bap-primus bap-std bap-taint core_kernel monads
                           ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-primus-random =  {
    name = "bap-primus-random";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-random/bap-primus-random.2.4.0/opam";
    depends = with self; [ bap-main bap-primus bap-std bitvec bitvec-sexp
                           core_kernel ocaml ppx_bap zarith ];
    depexts = [ ];
  };
  bap-primus-region =  {
    name = "bap-primus-region";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-region/bap-primus-region.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-round-robin-scheduler =  {
    name = "bap-primus-round-robin-scheduler";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-round-robin-scheduler/bap-primus-round-robin-scheduler.2.4.0/opam";
    depends = with self; [ bap-future bap-primus bap-std monads ocaml ];
    depexts = [ ];
  };
  bap-primus-support =  {
    name = "bap-primus-support";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-support/bap-primus-support.2.4.0/opam";
    depends = with self; [ bap-primus-exploring-scheduler
                           bap-primus-greedy-scheduler bap-primus-limit
                           bap-primus-loader bap-primus-mark-visited
                           bap-primus-print bap-primus-promiscuous
                           bap-primus-round-robin-scheduler
                           bap-primus-wandering-scheduler ];
    depexts = [ ];
  };
  bap-primus-systems =  {
    name = "bap-primus-systems";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-systems/bap-primus-systems.2.4.0/opam";
    depends = with self; [ bap-knowledge bap-main bap-primus bap-std
                           core_kernel ocaml ];
    depexts = [ ];
  };
  bap-primus-taint =  {
    name = "bap-primus-taint";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-taint/bap-primus-taint.2.4.0/opam";
    depends = with self; [ bap-primus bap-std bap-taint ocaml ];
    depexts = [ ];
  };
  bap-primus-test =  {
    name = "bap-primus-test";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-test/bap-primus-test.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-track-visited =  {
    name = "bap-primus-track-visited";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-track-visited/bap-primus-track-visited.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-primus-wandering-scheduler =  {
    name = "bap-primus-wandering-scheduler";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-wandering-scheduler/bap-primus-wandering-scheduler.2.4.0/opam";
    depends = with self; [ bap-future bap-primus bap-std monads ocaml ];
    depexts = [ ];
  };
  bap-primus-x86 =  {
    name = "bap-primus-x86";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-primus-x86/bap-primus-x86.2.4.0/opam";
    depends = with self; [ bap-primus bap-std bap-x86 ocaml ];
    depexts = [ ];
  };
  bap-print =  {
    name = "bap-print";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-print/bap-print.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-demangle bap-knowledge bap-std
                           core_kernel graphlib ocaml ogre ppx_bap re regular
                           text-tags ];
    depexts = [ ];
  };
  bap-raw =  {
    name = "bap-raw";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-raw/bap-raw.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-recipe =  {
    name = "bap-recipe";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-recipe/bap-recipe.2.4.0/opam";
    depends = with self; [ base camlzip fileutils oasis ocaml parsexp stdio
                           stdlib-shims uuidm ];
    depexts = [ ];
  };
  bap-recipe-command =  {
    name = "bap-recipe-command";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-recipe-command/bap-recipe-command.2.4.0/opam";
    depends = with self; [ bap-main bap-recipe bap-std base camlzip fileutils
                           ocaml parsexp stdio uuidm ];
    depexts = [ ];
  };
  bap-relation =  {
    name = "bap-relation";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-relation/bap-relation.2.4.0/opam";
    depends = with self; [ base oasis ocaml ];
    depexts = [ ];
  };
  bap-relocatable =  {
    name = "bap-relocatable";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-relocatable/bap-relocatable.2.4.0/opam";
    depends = with self; [ bap-abi bap-arm bap-core-theory bap-knowledge
                           bap-main bap-powerpc bap-relation bap-std bap-x86
                           bitvec bitvec-order bitvec-sexp core_kernel monads
                           ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-report =  {
    name = "bap-report";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-report/bap-report.2.4.0/opam";
    depends = with self; [ bap-std ocaml ];
    depexts = [ ];
  };
  bap-riscv =  {
    name = "bap-riscv";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-riscv/bap-riscv.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-c bap-core-theory
                           bap-knowledge bap-main bap-std core_kernel monads
                           ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-run =  {
    name = "bap-run";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-run/bap-run.2.4.0/opam";
    depends = with self; [ bap-primus bap-std ocaml ];
    depexts = [ ];
  };
  bap-signatures =  {
    name = "bap-signatures";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/releases/download/v2.4.0/sigs.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-signatures/bap-signatures.2.4.0/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  bap-specification =  {
    name = "bap-specification";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-specification/bap-specification.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel oasis ocaml ogre ];
    depexts = [ ];
  };
  bap-ssa =  {
    name = "bap-ssa";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-ssa/bap-ssa.2.4.0/opam";
    depends = with self; [ bap-std ocaml ];
    depexts = [ ];
  };
  bap-std =  {
    name = "bap-std";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-std/bap-std.2.4.0/opam";
    depends = with self; [ bap-bundle bap-core-theory bap-future
                           bap-knowledge bap-main bap-plugins bap-relation
                           base-unix bin_prot bitvec bitvec-order camlzip
                           cmdliner conf-clang conf-gmp conf-m4 conf-perl
                           conf-which core_kernel fileutils graphlib monads
                           oasis ocaml ocamlfind ogre ppx_bap regular result
                           uri utop uuidm zarith ];
    depexts = [ pkgs.binutils pkgs.zlib ];
  };
  bap-strings =  {
    name = "bap-strings";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-strings/bap-strings.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  bap-stub-resolver =  {
    name = "bap-stub-resolver";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-stub-resolver/bap-stub-resolver.2.4.0/opam";
    depends = with self; [ bap-abi bap-core-theory bap-knowledge bap-main
                           bap-relation bap-std bitvec bitvec-order
                           bitvec-sexp core_kernel ocaml ogre ounit ppx_bap ];
    depexts = [ ];
  };
  bap-symbol-reader =  {
    name = "bap-symbol-reader";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-symbol-reader/bap-symbol-reader.2.4.0/opam";
    depends = with self; [ bap-future bap-knowledge bap-std core_kernel oasis
                           ocaml ppx_bap regular ];
    depexts = [ ];
  };
  bap-systemz =  {
    name = "bap-systemz";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-systemz/bap-systemz.2.4.0/opam";
    depends = with self; [ bap-core-theory bap-knowledge bap-main bap-std
                           bitvec core_kernel ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-taint =  {
    name = "bap-taint";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-taint/bap-taint.2.4.0/opam";
    depends = with self; [ bap-primus bap-std bap-strings core_kernel monads
                           ocaml ppx_bap regular ];
    depexts = [ ];
  };
  bap-taint-propagator =  {
    name = "bap-taint-propagator";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-taint-propagator/bap-taint-propagator.2.4.0/opam";
    depends = with self; [ bap-microx bap-std cmdliner ocaml ];
    depexts = [ ];
  };
  bap-term-mapper =  {
    name = "bap-term-mapper";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-term-mapper/bap-term-mapper.2.4.0/opam";
    depends = with self; [ bap-main bap-std core_kernel oasis ocaml ppx_bap
                           regular ];
    depexts = [ ];
  };
  bap-thumb =  {
    name = "bap-thumb";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-thumb/bap-thumb.2.4.0/opam";
    depends = with self; [ bap-arm bap-core-theory bap-knowledge bap-main
                           bap-std bitvec core_kernel ocaml ogre ppx_bap ];
    depexts = [ ];
  };
  bap-toplevel =  {
    name = "bap-toplevel";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-toplevel/bap-toplevel.2.4.0/opam";
    depends = with self; [ bap-std oasis ocaml ocamlfind ];
    depexts = [ ];
  };
  bap-trivial-condition-form =  {
    name = "bap-trivial-condition-form";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-trivial-condition-form/bap-trivial-condition-form.2.4.0/opam";
    depends = with self; [ bap-std ocaml ];
    depexts = [ ];
  };
  bap-warn-unused =  {
    name = "bap-warn-unused";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-warn-unused/bap-warn-unused.2.4.0/opam";
    depends = with self; [ bap-std cmdliner oasis ocaml ];
    depexts = [ ];
  };
  bap-x86 =  {
    name = "bap-x86";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bap-x86/bap-x86.2.4.0/opam";
    depends = with self; [ bap-abi bap-api bap-c bap-core-theory bap-future
                           bap-knowledge bap-llvm bap-main bap-std bitvec
                           cmdliner core_kernel ocaml ogre ppx_bap regular ];
    depexts = [ ];
  };
  bare =  {
    name = "bare";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bare/bare.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml parsexp ];
    depexts = [ ];
  };
  base =  {
    name = "base";
    version = "v0.14.3";
    src = pkgs.fetchurl {
      url = "https://github.com/janestreet/base/archive/v0.14.3.tar.gz";
      sha256 = "e34dc0dd052a386c84f5f67e71a90720dff76e0edd01f431604404bee86ebe5a";
    };
    opam = "${opam-repo}/packages/base/base.v0.14.3/opam";
    depends = with self; [ dune dune-configurator ocaml sexplib0 ];
    depexts = [ ];
  };
  base-bigarray =  {
    name = "base-bigarray";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-bigarray/base-bigarray.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  base-bytes =  {
    name = "base-bytes";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-bytes/base-bytes.base/opam";
    depends = with self; [ ocaml ocamlfind ];
    depexts = [ ];
  };
  base-threads =  {
    name = "base-threads";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-threads/base-threads.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  base-unix =  {
    name = "base-unix";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/base-unix/base-unix.base/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  base_bigstring =  {
    name = "base_bigstring";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/base_bigstring-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/base_bigstring/base_bigstring.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_jane ];
    depexts = [ ];
  };
  base_quickcheck =  {
    name = "base_quickcheck";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/base_quickcheck/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/base_quickcheck/base_quickcheck.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppx_base ppx_fields_conv ppx_let
                           ppx_sexp_message ppx_sexp_value ppxlib
                           splittable_random ];
    depexts = [ ];
  };
  bigarray-compat =  {
    name = "bigarray-compat";
    version = "1.1.0";
    src = pkgs.fetchurl {
      url = "https://github.com/mirage/bigarray-compat/releases/download/v1.1.0/bigarray-compat-1.1.0.tbz";
      sha256 = "434469a48d5c84e80d621b13d95eb067f8138c1650a1fd5ae6009a19b93718d5";
    };
    opam = "${opam-repo}/packages/bigarray-compat/bigarray-compat.1.1.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  bigstringaf =  {
    name = "bigstringaf";
    version = "0.9.0";
    src = builtins.fetchurl {
      url = "https://github.com/inhabitedtype/bigstringaf/archive/0.9.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bigstringaf/bigstringaf.0.9.0/opam";
    depends = with self; [ conf-pkg-config dune ocaml
                           (self.ocaml-freestanding or null) ];
    depexts = [ ];
  };
  bin_prot =  {
    name = "bin_prot";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/bin_prot-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bin_prot/bin_prot.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_compare ppx_custom_printf
                           ppx_fields_conv ppx_optcomp ppx_sexp_conv
                           ppx_variants_conv (self.mirage-xen-ocaml or null) ];
    depexts = [ ];
  };
  bitvec =  {
    name = "bitvec";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bitvec/bitvec.2.4.0/opam";
    depends = with self; [ oasis ocaml zarith ];
    depexts = [ ];
  };
  bitvec-binprot =  {
    name = "bitvec-binprot";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bitvec-binprot/bitvec-binprot.2.4.0/opam";
    depends = with self; [ bin_prot bitvec oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  bitvec-order =  {
    name = "bitvec-order";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bitvec-order/bitvec-order.2.4.0/opam";
    depends = with self; [ base bitvec bitvec-sexp oasis ocaml ];
    depexts = [ ];
  };
  bitvec-sexp =  {
    name = "bitvec-sexp";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/bitvec-sexp/bitvec-sexp.2.4.0/opam";
    depends = with self; [ bitvec oasis ocaml sexplib0 ];
    depexts = [ pkgs.which ];
  };
  camlzip =  {
    name = "camlzip";
    version = "1.11";
    src = pkgs.fetchurl {
      url = "https://github.com/xavierleroy/camlzip/archive/rel111.tar.gz";
      sha256 = "ffbbc5de3e1c13dc0e59272376d232d2ede91b327551063d47fddb74f1d5ed37";
    };
    opam = "${opam-repo}/packages/camlzip/camlzip.1.11/opam";
    depends = with self; [ conf-zlib ocaml ocamlfind ];
    depexts = [ ];
  };
  camomile =  {
    name = "camomile";
    version = "1.0.2";
    src = pkgs.fetchurl {
      url = "https://github.com/yoriyuki/Camomile/releases/download/1.0.2/camomile-1.0.2.tbz";
      sha256 = "f0a419b0affc36500f83b086ffaa36c545560cee5d57e84b729e8f851b3d1632";
    };
    opam = "${opam-repo}/packages/camomile/camomile.1.0.2/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  charInfo_width =  {
    name = "charInfo_width";
    version = "1.1.0";
    src = builtins.fetchurl {
      url = "https://github.com/kandu/charInfo_width/archive/1.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/charInfo_width/charInfo_width.1.1.0/opam";
    depends = with self; [ camomile dune ocaml result ];
    depexts = [ ];
  };
  cmdliner =  {
    name = "cmdliner";
    version = "1.1.1";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/cmdliner/releases/cmdliner-1.1.1.tbz";
      sha512 = "5478ad833da254b5587b3746e3a8493e66e867a081ac0f653a901cc8a7d944f66e4387592215ce25d939be76f281c4785702f54d4a74b1700bc8838a62255c9e";
    };
    opam = "${opam-repo}/packages/cmdliner/cmdliner.1.1.1/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  conf-bap-llvm =  {
    name = "conf-bap-llvm";
    version = "1.7";
    src = null;
    opam = "${opam-repo}/packages/conf-bap-llvm/conf-bap-llvm.1.7/opam";
    depends = with self; [ base-unix conf-which ocaml ];
    depexts = [ pkgs.llvm.dev ];
  };
  conf-binutils =  {
    name = "conf-binutils";
    version = "0.3";
    src = null;
    opam = "${opam-repo}/packages/conf-binutils/conf-binutils.0.3/opam";
    depends = with self; [ base-unix ocaml ];
    depexts = [ pkgs.binutils ];
  };
  conf-clang =  {
    name = "conf-clang";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-clang/conf-clang.1/opam";
    depends = with self; [ ];
    depexts = [ (pkgs.clang or null) ];
  };
  conf-env-travis =  {
    name = "conf-env-travis";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-env-travis/conf-env-travis.1/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  conf-gmp =  {
    name = "conf-gmp";
    version = "4";
    src = null;
    opam = "${opam-repo}/packages/conf-gmp/conf-gmp.4/opam";
    depends = with self; [ ];
    depexts = [ pkgs.gmp ];
  };
  conf-m4 =  {
    name = "conf-m4";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-m4/conf-m4.1/opam";
    depends = with self; [ ];
    depexts = [ pkgs.m4 ];
  };
  conf-perl =  {
    name = "conf-perl";
    version = "2";
    src = null;
    opam = "${opam-repo}/packages/conf-perl/conf-perl.2/opam";
    depends = with self; [ ];
    depexts = [ pkgs.perl ];
  };
  conf-pkg-config =  {
    name = "conf-pkg-config";
    version = "2";
    src = null;
    opam = "${opam-repo}/packages/conf-pkg-config/conf-pkg-config.2/opam";
    depends = with self; [ ];
    depexts = [ pkgs.pkgconfig ];
  };
  conf-which =  {
    name = "conf-which";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-which/conf-which.1/opam";
    depends = with self; [ ];
    depexts = [ pkgs.which ];
  };
  conf-zlib =  {
    name = "conf-zlib";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/conf-zlib/conf-zlib.1/opam";
    depends = with self; [ conf-pkg-config ];
    depexts = [ pkgs.zlib ];
  };
  core_kernel =  {
    name = "core_kernel";
    version = "v0.14.2";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/core_kernel/archive/v0.14.2.tar.gz";
    };
    opam = "${opam-repo}/packages/core_kernel/core_kernel.v0.14.2/opam";
    depends = with self; [ base base_bigstring base_quickcheck bin_prot dune
                           fieldslib jane-street-headers jst-config ocaml
                           ppx_assert ppx_base ppx_hash ppx_inline_test
                           ppx_jane ppx_optcomp ppx_sexp_conv
                           ppx_sexp_message sexplib splittable_random stdio
                           time_now typerep variantslib ];
    depexts = [ ];
  };
  cppo =  {
    name = "cppo";
    version = "1.6.9";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-community/cppo/archive/v1.6.9.tar.gz";
      sha512 = "26ff5a7b7f38c460661974b23ca190f0feae3a99f1974e0fd12ccf08745bd7d91b7bc168c70a5385b837bfff9530e0e4e41cf269f23dd8cf16ca658008244b44";
    };
    opam = "${opam-repo}/packages/cppo/cppo.1.6.9/opam";
    depends = with self; [ base-unix dune ocaml ];
    depexts = [ ];
  };
  csexp =  {
    name = "csexp";
    version = "1.5.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-dune/csexp/releases/download/1.5.1/csexp-1.5.1.tbz";
      sha256 = "d605e4065fa90a58800440ef2f33a2d931398bf2c22061a8acb7df845c0aac02";
    };
    opam = "${opam-repo}/packages/csexp/csexp.1.5.1/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  dune =  {
    name = "dune";
    version = "3.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/dune/releases/download/3.2.0/chrome-trace-3.2.0.tbz";
      sha256 = "bd1fbce6ae79ed1eb26fa89bb2e2e23978afceb3f53f5578cf1bdab08a1ad5bc";
    };
    opam = "${opam-repo}/packages/dune/dune.3.2.0/opam";
    depends = with self; [ base-threads base-unix (self.ocaml or null)
                           (self.ocamlfind-secondary or null) ];
    depexts = [ ];
  };
  dune-configurator =  {
    name = "dune-configurator";
    version = "3.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/dune/releases/download/3.2.0/chrome-trace-3.2.0.tbz";
      sha256 = "bd1fbce6ae79ed1eb26fa89bb2e2e23978afceb3f53f5578cf1bdab08a1ad5bc";
    };
    opam = "${opam-repo}/packages/dune-configurator/dune-configurator.3.2.0/opam";
    depends = with self; [ csexp dune ocaml ];
    depexts = [ ];
  };
  FrontC =  {
    name = "FrontC";
    version = "4.1.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/FrontC/archive/refs/tags/v4.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/FrontC/FrontC.4.1.0/opam";
    depends = with self; [ dune menhir ocaml ];
    depexts = [ ];
  };
  fieldslib =  {
    name = "fieldslib";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/fieldslib-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/fieldslib/fieldslib.v0.14.0/opam";
    depends = with self; [ base dune ocaml ];
    depexts = [ ];
  };
  fileutils =  {
    name = "fileutils";
    version = "0.6.3";
    src = pkgs.fetchurl {
      url = "https://github.com/gildor478/ocaml-fileutils/releases/download/v0.6.3/fileutils-v0.6.3.tbz";
      sha256 = "eff581c488e9309eb02268bbfa3d4c9c30ff40d45f7b1e9ef300b3ef0e831462";
    };
    opam = "${opam-repo}/packages/fileutils/fileutils.0.6.3/opam";
    depends = with self; [ base-bytes base-unix dune ocaml stdlib-shims ];
    depexts = [ ];
  };
  fmt =  {
    name = "fmt";
    version = "0.9.0";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/fmt/releases/fmt-0.9.0.tbz";
      sha512 = "66cf4b8bb92232a091dfda5e94d1c178486a358cdc34b1eec516d48ea5acb6209c0dfcb416f0c516c50ddbddb3c94549a45e4a6d5c5fd1c81d3374dec823a83b";
    };
    opam = "${opam-repo}/packages/fmt/fmt.0.9.0/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg
                           (self.base-unix or null) (self.cmdliner or null) ];
    depexts = [ ];
  };
  graphlib =  {
    name = "graphlib";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/graphlib/graphlib.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ocamlgraph ppx_bap regular ];
    depexts = [ ];
  };
  jane-street-headers =  {
    name = "jane-street-headers";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/jane-street-headers-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/jane-street-headers/jane-street-headers.v0.14.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  jst-config =  {
    name = "jst-config";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/jst-config/archive/refs/tags/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/jst-config/jst-config.v0.14.1/opam";
    depends = with self; [ base dune dune-configurator ocaml ppx_assert stdio ];
    depexts = [ ];
  };
  lambda-term =  {
    name = "lambda-term";
    version = "3.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-community/lambda-term/releases/download/3.2.0/lambda-term-3.2.0.tar.gz";
      sha512 = "46cd46f47c9f34c0a5e096b96e6eec59667b645bf5201140e498e6d4eb9baba8204a2b30b73c4b2f8140e5cf1972a56e3aa485b27bc5ace25b2c368f713ad7c4";
    };
    opam = "${opam-repo}/packages/lambda-term/lambda-term.3.2.0/opam";
    depends = with self; [ camomile dune lwt lwt_log lwt_react mew_vi ocaml
                           react zed ];
    depexts = [ ];
  };
  linenoise =  {
    name = "linenoise";
    version = "1.3.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-community/ocaml-linenoise/archive/v1.3.1.tar.gz";
      sha512 = "02d5c002a37b41254d6f9d1645117b99209129ba8b808871e6bd48ab2c8c4486fa12aca98db9a8cd44fafccca4c88b517fe0311afbcb9791f270a7329176f793";
    };
    opam = "${opam-repo}/packages/linenoise/linenoise.1.3.1/opam";
    depends = with self; [ dune ocaml result ];
    depexts = [ ];
  };
  lwt =  {
    name = "lwt";
    version = "5.5.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocsigen/lwt/archive/refs/tags/5.5.0.tar.gz";
      sha512 = "8951b94555e930634375816d71815b9d85daad6ffb7dab24864661504d11be26575ab0b237196c54693efa372a9b69cdc1d5068a20a250dc0bbb4a3c03c5fda1";
    };
    opam = "${opam-repo}/packages/lwt/lwt.5.5.0/opam";
    depends = with self; [ cppo dune dune-configurator mmap ocaml
                           ocplib-endian result seq
                           (self.base-threads or null)
                           (self.base-unix or null) (self.conf-libev or null)
                           (self.ocaml or null)
                           (self.ocaml-syntax-shims or null) ];
    depexts = [ ];
  };
  lwt_log =  {
    name = "lwt_log";
    version = "1.1.1";
    src = builtins.fetchurl {
      url = "https://github.com/aantron/lwt_log/archive/1.1.1.tar.gz";
    };
    opam = "${opam-repo}/packages/lwt_log/lwt_log.1.1.1/opam";
    depends = with self; [ dune lwt ];
    depexts = [ ];
  };
  lwt_react =  {
    name = "lwt_react";
    version = "1.1.5";
    src = pkgs.fetchurl {
      url = "https://github.com/ocsigen/lwt/archive/refs/tags/5.5.0.tar.gz";
      sha512 = "8951b94555e930634375816d71815b9d85daad6ffb7dab24864661504d11be26575ab0b237196c54693efa372a9b69cdc1d5068a20a250dc0bbb4a3c03c5fda1";
    };
    opam = "${opam-repo}/packages/lwt_react/lwt_react.1.1.5/opam";
    depends = with self; [ dune lwt ocaml react ];
    depexts = [ ];
  };
  menhir =  {
    name = "menhir";
    version = "20220210";
    src = pkgs.fetchurl {
      url = "https://gitlab.inria.fr/fpottier/menhir/-/archive/20220210/archive.tar.gz";
      sha512 = "3063fec1d8b9fe092c8461b0689d426c7fe381a2bf3fd258dc42ceecca1719d32efbb8a18d94ada5555c38175ea352da3adbb239fdbcbcf52c3a5c85a4d9586f";
    };
    opam = "${opam-repo}/packages/menhir/menhir.20220210/opam";
    depends = with self; [ dune menhirLib menhirSdk ocaml ];
    depexts = [ ];
  };
  menhirLib =  {
    name = "menhirLib";
    version = "20220210";
    src = pkgs.fetchurl {
      url = "https://gitlab.inria.fr/fpottier/menhir/-/archive/20220210/archive.tar.gz";
      sha512 = "3063fec1d8b9fe092c8461b0689d426c7fe381a2bf3fd258dc42ceecca1719d32efbb8a18d94ada5555c38175ea352da3adbb239fdbcbcf52c3a5c85a4d9586f";
    };
    opam = "${opam-repo}/packages/menhirLib/menhirLib.20220210/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  menhirSdk =  {
    name = "menhirSdk";
    version = "20220210";
    src = pkgs.fetchurl {
      url = "https://gitlab.inria.fr/fpottier/menhir/-/archive/20220210/archive.tar.gz";
      sha512 = "3063fec1d8b9fe092c8461b0689d426c7fe381a2bf3fd258dc42ceecca1719d32efbb8a18d94ada5555c38175ea352da3adbb239fdbcbcf52c3a5c85a4d9586f";
    };
    opam = "${opam-repo}/packages/menhirSdk/menhirSdk.20220210/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  mew =  {
    name = "mew";
    version = "0.1.0";
    src = builtins.fetchurl {
      url = "https://github.com/kandu/mew/archive/0.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/mew/mew.0.1.0/opam";
    depends = with self; [ dune ocaml result trie ];
    depexts = [ ];
  };
  mew_vi =  {
    name = "mew_vi";
    version = "0.5.0";
    src = builtins.fetchurl {
      url = "https://github.com/kandu/mew_vi/archive/0.5.0.tar.gz";
    };
    opam = "${opam-repo}/packages/mew_vi/mew_vi.0.5.0/opam";
    depends = with self; [ dune mew ocaml react ];
    depexts = [ ];
  };
  mmap =  {
    name = "mmap";
    version = "1.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/mirage/mmap/releases/download/v1.2.0/mmap-1.2.0.tbz";
      sha256 = "1602a8abc8e232fa94771a52e540e5780b40c2f2762eee6afbd9286502116ddb";
    };
    opam = "${opam-repo}/packages/mmap/mmap.1.2.0/opam";
    depends = with self; [ bigarray-compat dune ocaml ];
    depexts = [ ];
  };
  monads =  {
    name = "monads";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/monads/monads.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  num =  {
    name = "num";
    version = "1.4";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/num/archive/v1.4.tar.gz";
      sha512 = "0cc9be8ad95704bb683b4bf6698bada1ee9a40dc05924b72adc7b969685c33eeb68ccf174cc09f6a228c48c18fe94af06f28bebc086a24973a066da620db8e6f";
    };
    opam = "${opam-repo}/packages/num/num.1.4/opam";
    depends = with self; [ ocaml ocamlfind ];
    depexts = [ ];
  };
  oasis =  {
    name = "oasis";
    version = "0.4.11";
    src = builtins.fetchurl {
      url = "https://download.ocamlcore.org/oasis/oasis/0.4.11/oasis-0.4.11.tar.gz";
    };
    opam = "${opam-repo}/packages/oasis/oasis.0.4.11/opam";
    depends = with self; [ base-unix ocaml ocamlbuild ocamlfind ocamlify
                           ocamlmod (self.benchmark or null) ];
    depexts = [ ];
  };
  ocaml =  {
    name = "ocaml";
    version = "4.14.0";
    src = null;
    opam = "${opam-repo}/packages/ocaml/ocaml.4.14.0/opam";
    depends = with self; [ ocaml-config (self.ocaml-base-compiler or null)
                           (self.ocaml-system or null)
                           (self.ocaml-variants or null) ];
    depexts = [ ];
  };
  ocaml-base-compiler =  {
    name = "ocaml-base-compiler";
    version = "4.14.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocaml/archive/4.14.0.tar.gz";
      sha256 = "39f44260382f28d1054c5f9d8bf4753cb7ad64027da792f7938344544da155e8";
    };
    opam = "${opam-repo}/packages/ocaml-base-compiler/ocaml-base-compiler.4.14.0/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  ocaml-compiler-libs =  {
    name = "ocaml-compiler-libs";
    version = "v0.12.4";
    src = pkgs.fetchurl {
      url = "https://github.com/janestreet/ocaml-compiler-libs/releases/download/v0.12.4/ocaml-compiler-libs-v0.12.4.tbz";
      sha256 = "4ec9c9ec35cc45c18c7a143761154ef1d7663036a29297f80381f47981a07760";
    };
    opam = "${opam-repo}/packages/ocaml-compiler-libs/ocaml-compiler-libs.v0.12.4/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ocaml-config =  {
    name = "ocaml-config";
    version = "2";
    src = null;
    opam = "${opam-repo}/packages/ocaml-config/ocaml-config.2/opam";
    depends = with self; [ (self.ocaml-base-compiler or null)
                           (self.ocaml-system or null)
                           (self.ocaml-variants or null) ];
    depexts = [ ];
  };
  ocaml-options-vanilla =  {
    name = "ocaml-options-vanilla";
    version = "1";
    src = null;
    opam = "${opam-repo}/packages/ocaml-options-vanilla/ocaml-options-vanilla.1/opam";
    depends = with self; [ ];
    depexts = [ ];
  };
  ocaml-syntax-shims =  {
    name = "ocaml-syntax-shims";
    version = "1.0.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-ppx/ocaml-syntax-shims/releases/download/1.0.0/ocaml-syntax-shims-1.0.0.tbz";
      sha256 = "89b2e193e90a0c168b6ec5ddf6fef09033681bdcb64e11913c97440a2722e8c8";
    };
    opam = "${opam-repo}/packages/ocaml-syntax-shims/ocaml-syntax-shims.1.0.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ocamlbuild =  {
    name = "ocamlbuild";
    version = "0.14.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocamlbuild/archive/refs/tags/0.14.1.tar.gz";
      sha512 = "1f5b43215b1d3dc427b9c64e005add9d423ed4bca9686d52c55912df8955647cb2d7d86622d44b41b14c4f0d657b770c27967c541c868eeb7c78e3bd35b827ad";
    };
    opam = "${opam-repo}/packages/ocamlbuild/ocamlbuild.0.14.1/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  ocamlfind =  {
    name = "ocamlfind";
    version = "1.9.3";
    src = pkgs.fetchurl {
      url = "http://download.camlcity.org/download/findlib-1.9.3.tar.gz";
      sha512 = "27cc4ce141576bf477fb9d61a82ad65f55478740eed59fb43f43edb794140829fd2ff89ad27d8a890cfc336b54c073a06de05b31100fc7c01cacbd7d88e928ea";
    };
    opam = "${opam-repo}/packages/ocamlfind/ocamlfind.1.9.3/opam";
    depends = with self; [ ocaml (self.graphics or null) ];
    depexts = [ ];
  };
  ocamlgraph =  {
    name = "ocamlgraph";
    version = "2.0.0";
    src = pkgs.fetchurl {
      url = "https://github.com/backtracking/ocamlgraph/releases/download/2.0.0/ocamlgraph-2.0.0.tbz";
      sha256 = "20fe267797de5322088a4dfb52389b2ea051787952a8a4f6ed70fcb697482609";
    };
    opam = "${opam-repo}/packages/ocamlgraph/ocamlgraph.2.0.0/opam";
    depends = with self; [ dune ocaml stdlib-shims ];
    depexts = [ ];
  };
  ocamlify =  {
    name = "ocamlify";
    version = "0.0.1";
    src = builtins.fetchurl {
      url = "https://download.ocamlcore.org/ocamlify/ocamlify/0.0.1/ocamlify-0.0.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ocamlify/ocamlify.0.0.1/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind ];
    depexts = [ ];
  };
  ocamlmod =  {
    name = "ocamlmod";
    version = "0.0.9";
    src = builtins.fetchurl {
      url = "https://download.ocamlcore.org/ocamlmod/ocamlmod/0.0.9/ocamlmod-0.0.9.tar.gz";
    };
    opam = "${opam-repo}/packages/ocamlmod/ocamlmod.0.0.9/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind ];
    depexts = [ ];
  };
  ocplib-endian =  {
    name = "ocplib-endian";
    version = "1.2";
    src = pkgs.fetchurl {
      url = "https://github.com/OCamlPro/ocplib-endian/archive/refs/tags/1.2.tar.gz";
      sha512 = "2e70be5f3d6e377485c60664a0e235c3b9b24a8d6b6a03895d092c6e40d53810bfe1f292ee69e5181ce6daa8a582bfe3d59f3af889f417134f658812be5b8b85";
    };
    opam = "${opam-repo}/packages/ocplib-endian/ocplib-endian.1.2/opam";
    depends = with self; [ base-bytes cppo dune ocaml ];
    depexts = [ ];
  };
  octavius =  {
    name = "octavius";
    version = "1.2.2";
    src = builtins.fetchurl {
      url = "https://github.com/ocaml-doc/octavius/archive/v1.2.2.tar.gz";
    };
    opam = "${opam-repo}/packages/octavius/octavius.1.2.2/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ogre =  {
    name = "ogre";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ogre/ogre.2.4.0/opam";
    depends = with self; [ core_kernel monads oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  ounit =  {
    name = "ounit";
    version = "2.2.6";
    src = pkgs.fetchurl {
      url = "https://github.com/gildor478/ounit/releases/download/v2.2.6/ounit-2.2.6.tbz";
      sha256 = "0690fb1e0e90a18eed5c3566b3cc1825d98b0e8c7d51bb6b846c95c45a615913";
    };
    opam = "${opam-repo}/packages/ounit/ounit.2.2.6/opam";
    depends = with self; [ ocamlfind ounit2 ];
    depexts = [ ];
  };
  ounit2 =  {
    name = "ounit2";
    version = "2.2.6";
    src = pkgs.fetchurl {
      url = "https://github.com/gildor478/ounit/releases/download/v2.2.6/ounit-2.2.6.tbz";
      sha256 = "0690fb1e0e90a18eed5c3566b3cc1825d98b0e8c7d51bb6b846c95c45a615913";
    };
    opam = "${opam-repo}/packages/ounit2/ounit2.2.2.6/opam";
    depends = with self; [ base-bytes base-unix dune ocaml seq stdlib-shims ];
    depexts = [ ];
  };
  parsexp =  {
    name = "parsexp";
    version = "v0.14.2";
    src = pkgs.fetchurl {
      url = "https://github.com/janestreet/parsexp/archive/refs/tags/v0.14.2.tar.gz";
      sha256 = "f6e17e4e08dcdce08a6372485a381dcdb3fda0f71b4506d7be982b87b5a1f230";
    };
    opam = "${opam-repo}/packages/parsexp/parsexp.v0.14.2/opam";
    depends = with self; [ base dune ocaml sexplib0 ];
    depexts = [ ];
  };
  ppx_assert =  {
    name = "ppx_assert";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_assert-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_assert/ppx_assert.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_cold ppx_compare ppx_here
                           ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_bap =  {
    name = "ppx_bap";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/ppx_bap/archive/v0.14.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_bap/ppx_bap.v0.14.0/opam";
    depends = with self; [ base_quickcheck dune ocaml ppx_assert ppx_bench
                           ppx_bin_prot ppx_cold ppx_compare ppx_enumerate
                           ppx_fields_conv ppx_hash ppx_here ppx_optcomp
                           ppx_sexp_conv ppx_sexp_value ppx_variants_conv
                           ppxlib ];
    depexts = [ ];
  };
  ppx_base =  {
    name = "ppx_base";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_base-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_base/ppx_base.v0.14.0/opam";
    depends = with self; [ dune ocaml ppx_cold ppx_compare ppx_enumerate
                           ppx_hash ppx_js_style ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_bench =  {
    name = "ppx_bench";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_bench/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_bench/ppx_bench.v0.14.1/opam";
    depends = with self; [ dune ocaml ppx_inline_test ppxlib ];
    depexts = [ ];
  };
  ppx_bin_prot =  {
    name = "ppx_bin_prot";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_bin_prot-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_bin_prot/ppx_bin_prot.v0.14.0/opam";
    depends = with self; [ base bin_prot dune ocaml ppx_here ppxlib ];
    depexts = [ ];
  };
  ppx_cold =  {
    name = "ppx_cold";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_cold-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_cold/ppx_cold.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_compare =  {
    name = "ppx_compare";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_compare-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_compare/ppx_compare.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_custom_printf =  {
    name = "ppx_custom_printf";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_custom_printf/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_custom_printf/ppx_custom_printf.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_derivers =  {
    name = "ppx_derivers";
    version = "1.2.1";
    src = builtins.fetchurl {
      url = "https://github.com/ocaml-ppx/ppx_derivers/archive/1.2.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_derivers/ppx_derivers.1.2.1/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  ppx_enumerate =  {
    name = "ppx_enumerate";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_enumerate-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_enumerate/ppx_enumerate.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_expect =  {
    name = "ppx_expect";
    version = "v0.14.2";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_expect/archive/v0.14.2.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_expect/ppx_expect.v0.14.2/opam";
    depends = with self; [ base dune ocaml ppx_here ppx_inline_test ppxlib re
                           stdio ];
    depexts = [ ];
  };
  ppx_fields_conv =  {
    name = "ppx_fields_conv";
    version = "v0.14.2";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_fields_conv/archive/v0.14.2.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_fields_conv/ppx_fields_conv.v0.14.2/opam";
    depends = with self; [ base dune fieldslib ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_fixed_literal =  {
    name = "ppx_fixed_literal";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_fixed_literal-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_fixed_literal/ppx_fixed_literal.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_hash =  {
    name = "ppx_hash";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_hash-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_hash/ppx_hash.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_compare ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_here =  {
    name = "ppx_here";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_here-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_here/ppx_here.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_inline_test =  {
    name = "ppx_inline_test";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_inline_test/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_inline_test/ppx_inline_test.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppxlib time_now ];
    depexts = [ ];
  };
  ppx_jane =  {
    name = "ppx_jane";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_jane-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_jane/ppx_jane.v0.14.0/opam";
    depends = with self; [ base_quickcheck dune ocaml ppx_assert ppx_base
                           ppx_bench ppx_bin_prot ppx_custom_printf
                           ppx_expect ppx_fields_conv ppx_fixed_literal
                           ppx_here ppx_inline_test ppx_let ppx_module_timer
                           ppx_optcomp ppx_optional ppx_pipebang
                           ppx_sexp_message ppx_sexp_value ppx_stable
                           ppx_string ppx_typerep_conv ppx_variants_conv
                           ppxlib ];
    depexts = [ ];
  };
  ppx_js_style =  {
    name = "ppx_js_style";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_js_style/archive/refs/tags/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_js_style/ppx_js_style.v0.14.1/opam";
    depends = with self; [ base dune ocaml octavius ppxlib ];
    depexts = [ ];
  };
  ppx_let =  {
    name = "ppx_let";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_let-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_let/ppx_let.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_module_timer =  {
    name = "ppx_module_timer";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_module_timer-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_module_timer/ppx_module_timer.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_base ppxlib stdio time_now ];
    depexts = [ ];
  };
  ppx_optcomp =  {
    name = "ppx_optcomp";
    version = "v0.14.3";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_optcomp/archive/v0.14.3.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_optcomp/ppx_optcomp.v0.14.3/opam";
    depends = with self; [ base dune ocaml ppxlib stdio ];
    depexts = [ ];
  };
  ppx_optional =  {
    name = "ppx_optional";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_optional-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_optional/ppx_optional.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_pipebang =  {
    name = "ppx_pipebang";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_pipebang-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_pipebang/ppx_pipebang.v0.14.0/opam";
    depends = with self; [ dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_sexp_conv =  {
    name = "ppx_sexp_conv";
    version = "v0.14.3";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_sexp_conv/archive/v0.14.3.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_sexp_conv/ppx_sexp_conv.v0.14.3/opam";
    depends = with self; [ base dune ocaml ppxlib sexplib0 ];
    depexts = [ ];
  };
  ppx_sexp_message =  {
    name = "ppx_sexp_message";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_sexp_message/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_sexp_message/ppx_sexp_message.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppx_here ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_sexp_value =  {
    name = "ppx_sexp_value";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/ppx_sexp_value-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_sexp_value/ppx_sexp_value.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_here ppx_sexp_conv ppxlib ];
    depexts = [ ];
  };
  ppx_stable =  {
    name = "ppx_stable";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_stable/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_stable/ppx_stable.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppxlib ];
    depexts = [ ];
  };
  ppx_string =  {
    name = "ppx_string";
    version = "v0.14.1";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_string/archive/v0.14.1.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_string/ppx_string.v0.14.1/opam";
    depends = with self; [ base dune ocaml ppx_base ppxlib stdio ];
    depexts = [ ];
  };
  ppx_typerep_conv =  {
    name = "ppx_typerep_conv";
    version = "v0.14.2";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_typerep_conv/archive/v0.14.2.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_typerep_conv/ppx_typerep_conv.v0.14.2/opam";
    depends = with self; [ base dune ocaml ppxlib typerep ];
    depexts = [ ];
  };
  ppx_variants_conv =  {
    name = "ppx_variants_conv";
    version = "v0.14.2";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/ppx_variants_conv/archive/v0.14.2.tar.gz";
    };
    opam = "${opam-repo}/packages/ppx_variants_conv/ppx_variants_conv.v0.14.2/opam";
    depends = with self; [ base dune ocaml ppxlib variantslib ];
    depexts = [ ];
  };
  ppxlib =  {
    name = "ppxlib";
    version = "0.25.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-ppx/ppxlib/releases/download/0.25.0/ppxlib-0.25.0.tbz";
      sha256 = "2d2f150e7715845dc578d254f705a67600be71c986b7e67e81befda612870bd5";
    };
    opam = "${opam-repo}/packages/ppxlib/ppxlib.0.25.0/opam";
    depends = with self; [ dune ocaml ocaml-compiler-libs ppx_derivers
                           sexplib0 stdlib-shims ];
    depexts = [ ];
  };
  re =  {
    name = "re";
    version = "1.10.4";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/ocaml-re/releases/download/1.10.4/re-1.10.4.tbz";
      sha256 = "83eb3e4300aa9b1dc7820749010f4362ea83524742130524d78c20ce99ca747c";
    };
    opam = "${opam-repo}/packages/re/re.1.10.4/opam";
    depends = with self; [ dune ocaml seq ];
    depexts = [ ];
  };
  react =  {
    name = "react";
    version = "1.2.2";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/react/releases/react-1.2.2.tbz";
      sha512 = "18cdd544d484222ba02db6bd9351571516532e7a1c107b59bbe39193837298f5c745eab6754f8bc6ff125b387be7018c6d6e6ac99f91925a5e4f53af688522b1";
    };
    opam = "${opam-repo}/packages/react/react.1.2.2/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg ];
    depexts = [ ];
  };
  regular =  {
    name = "regular";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/regular/regular.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ppx_bap ];
    depexts = [ ];
  };
  result =  {
    name = "result";
    version = "1.5";
    src = builtins.fetchurl {
      url = "https://github.com/janestreet/result/releases/download/1.5/result-1.5.tbz";
    };
    opam = "${opam-repo}/packages/result/result.1.5/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  seq =  {
    name = "seq";
    version = "base";
    src = null;
    opam = "${opam-repo}/packages/seq/seq.base/opam";
    depends = with self; [ ocaml ];
    depexts = [ ];
  };
  sexplib =  {
    name = "sexplib";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/sexplib-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/sexplib/sexplib.v0.14.0/opam";
    depends = with self; [ dune num ocaml parsexp sexplib0 ];
    depexts = [ ];
  };
  sexplib0 =  {
    name = "sexplib0";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/sexplib0-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/sexplib0/sexplib0.v0.14.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  splittable_random =  {
    name = "splittable_random";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/splittable_random-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/splittable_random/splittable_random.v0.14.0/opam";
    depends = with self; [ base dune ocaml ppx_assert ppx_bench
                           ppx_inline_test ppx_sexp_message ];
    depexts = [ ];
  };
  stdio =  {
    name = "stdio";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/stdio-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/stdio/stdio.v0.14.0/opam";
    depends = with self; [ base dune ocaml ];
    depexts = [ ];
  };
  stdlib-shims =  {
    name = "stdlib-shims";
    version = "0.3.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/stdlib-shims/releases/download/0.3.0/stdlib-shims-0.3.0.tbz";
      sha256 = "babf72d3917b86f707885f0c5528e36c63fccb698f4b46cf2bab5c7ccdd6d84a";
    };
    opam = "${opam-repo}/packages/stdlib-shims/stdlib-shims.0.3.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  stringext =  {
    name = "stringext";
    version = "1.6.0";
    src = pkgs.fetchurl {
      url = "https://github.com/rgrinberg/stringext/releases/download/1.6.0/stringext-1.6.0.tbz";
      sha256 = "db41f5d52e9eab17615f110b899dfeb27dd7e7f89cd35ae43827c5119db206ea";
    };
    opam = "${opam-repo}/packages/stringext/stringext.1.6.0/opam";
    depends = with self; [ base-bytes dune ocaml ];
    depexts = [ ];
  };
  text-tags =  {
    name = "text-tags";
    version = "2.4.0";
    src = builtins.fetchurl {
      url = "https://github.com/BinaryAnalysisPlatform/bap/archive/v2.4.0.tar.gz";
    };
    opam = "${opam-repo}/packages/text-tags/text-tags.2.4.0/opam";
    depends = with self; [ core_kernel oasis ocaml ];
    depexts = [ ];
  };
  time_now =  {
    name = "time_now";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/time_now-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/time_now/time_now.v0.14.0/opam";
    depends = with self; [ base dune jane-street-headers jst-config ocaml
                           ppx_base ppx_optcomp ];
    depexts = [ ];
  };
  topkg =  {
    name = "topkg";
    version = "1.0.5";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/topkg/releases/topkg-1.0.5.tbz";
      sha512 = "9450e9139209aacd8ddb4ba18e4225770837e526a52a56d94fd5c9c4c9941e83e0e7102e2292b440104f4c338fabab47cdd6bb51d69b41cc92cc7a551e6fefab";
    };
    opam = "${opam-repo}/packages/topkg/topkg.1.0.5/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind ];
    depexts = [ ];
  };
  trie =  {
    name = "trie";
    version = "1.0.0";
    src = builtins.fetchurl {
      url = "https://github.com/kandu/trie/archive/1.0.0.tar.gz";
    };
    opam = "${opam-repo}/packages/trie/trie.1.0.0/opam";
    depends = with self; [ dune ocaml ];
    depexts = [ ];
  };
  typerep =  {
    name = "typerep";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/typerep-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/typerep/typerep.v0.14.0/opam";
    depends = with self; [ base dune ocaml ];
    depexts = [ ];
  };
  universe = rec {
    name = "universe";
    version = "root";
    src = ./.;
    opam = "${src}/universe.opam";
    depends = with self; [ bap dune fmt ocaml ];
    depexts = [ ];
  };
  uri =  {
    name = "uri";
    version = "4.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/mirage/ocaml-uri/releases/download/v4.2.0/uri-v4.2.0.tbz";
      sha256 = "c5c013d940dbb6731ea2ee75c2bf991d3435149c3f3659ec2e55476f5473f16b";
    };
    opam = "${opam-repo}/packages/uri/uri.4.2.0/opam";
    depends = with self; [ angstrom dune ocaml stringext ];
    depexts = [ ];
  };
  utop =  {
    name = "utop";
    version = "2.9.1";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml-community/utop/releases/download/2.9.1/utop-2.9.1.tbz";
      sha512 = "002fa809d4924419f51b81df968b653a111ae5992837792fcb867adf2e44c15d40fadccc9784ef61f21ea3233f9da74016433920bf909d808752b7f825f8cdb1";
    };
    opam = "${opam-repo}/packages/utop/utop.2.9.1/opam";
    depends = with self; [ base-threads base-unix camomile cppo dune
                           lambda-term lwt lwt_react ocaml ocamlfind react ];
    depexts = [ ];
  };
  uuidm =  {
    name = "uuidm";
    version = "0.9.8";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/uuidm/releases/uuidm-0.9.8.tbz";
      sha512 = "d5073ae49c402ab3ea6dc8f86bc5b8cc14129437e23e47da4d91431648fcb31c4dce6308f9c936c58df9a2c6afda61d77105a3022e369cca4e4c140320e803b5";
    };
    opam = "${opam-repo}/packages/uuidm/uuidm.0.9.8/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg
                           (self.cmdliner or null) ];
    depexts = [ ];
  };
  variantslib =  {
    name = "variantslib";
    version = "v0.14.0";
    src = builtins.fetchurl {
      url = "https://ocaml.janestreet.com/ocaml-core/v0.14/files/variantslib-v0.14.0.tar.gz";
    };
    opam = "${opam-repo}/packages/variantslib/variantslib.v0.14.0/opam";
    depends = with self; [ base dune ocaml ];
    depexts = [ ];
  };
  xmlm =  {
    name = "xmlm";
    version = "1.4.0";
    src = pkgs.fetchurl {
      url = "https://erratique.ch/software/xmlm/releases/xmlm-1.4.0.tbz";
      sha512 = "69f6112e6466952256d670fe1751fe4ae79e20d50f018ece1709eb2240cb1b00968ac7cee110771e0617a38ebc1cdb43e9d146471ce66ac1b176e4a1660531eb";
    };
    opam = "${opam-repo}/packages/xmlm/xmlm.1.4.0/opam";
    depends = with self; [ ocaml ocamlbuild ocamlfind topkg ];
    depexts = [ ];
  };
  zarith =  {
    name = "zarith";
    version = "1.12";
    src = pkgs.fetchurl {
      url = "https://github.com/ocaml/Zarith/archive/release-1.12.tar.gz";
      sha512 = "8075573ae65579a2606b37dd1b213032a07d220d28c733f9288ae80d36f8a2cc4d91632806df2503c130ea9658dc207ee3a64347c21aa53969050a208f5b2bb4";
    };
    opam = "${opam-repo}/packages/zarith/zarith.1.12/opam";
    depends = with self; [ conf-gmp ocaml ocamlfind ];
    depexts = [ ];
  };
  zed =  {
    name = "zed";
    version = "3.1.0";
    src = builtins.fetchurl {
      url = "https://github.com/ocaml-community/zed/archive/3.1.0.tar.gz";
    };
    opam = "${opam-repo}/packages/zed/zed.3.1.0/opam";
    depends = with self; [ base-bytes camomile charInfo_width dune ocaml
                           react ];
    depexts = [ ];
  };
}
