(*

  Allowed vars:
  - os = linux | macos | win32 | cygwin | freebsd | openbsd | netbsd | dragonfly (uname -s)
    - possible = linux | macos
  - os-distribution = homebrew | macports | android | distro-name | $os
  - os-family = debian | bsd | windows
    - possible = nixos
  - arch
  - os-version = release id
  - jobs
  - make
  - with-test
  - with-doc
  - with-dev-setup
  - post?
  

 *)

let opamfile = "../../../tests/zarith.opam"
let opam = In_channel.with_open_text opamfile OpamFile.OPAM.read_from_channel
let build_commands = OpamFile.OPAM.build opam
let install_commands = OpamFile.OPAM.install opam
let depends = OpamFile.OPAM.depends opam

let dep_names =
  ["ocaml"; "ocamlfind"; "conf-gmp"; "ocaml-lsp-server"; "utop"; "foo"]

let ocaml_version = OpamPackage.Version.of_string "4.14.0"

let pkg_scope =
  let name = OpamPackage.Name.of_string "zarith" in
  let version = OpamPackage.Version.of_string "dev" in
  let dep_names =
    OpamPackage.Name.Set.of_list (List.map OpamPackage.Name.of_string dep_names)
  in
  let deps =
    OpamPackage.Name.Set.fold
      (fun name acc ->
        let prefix =
          String.concat "" ["${"; OpamPackage.Name.to_string name; "}"]
        in
        let pkg =
          Onix_core.Scope.make_pkg ~name
            ~version:(OpamPackage.Version.of_string "version_todo")
            ~opamfile:
              (Onix_core.Paths.lib ~pkg_name:name ~ocaml_version prefix
              ^ "/opam")
            ~prefix
        in
        OpamPackage.Name.Map.add name pkg acc)
      dep_names OpamPackage.Name.Map.empty
  in
  let self =
    Onix_core.Scope.make_pkg ~name ~version ~opamfile:"./zarith.opam"
      ~prefix:"$out"
  in
  Onix_core.Scope.make ~deps ~ocaml_version self

let env = Onix_lock_nix.Nix_pkg.resolve_commands pkg_scope

let process_commands commands =
  let commands' =
    Onix_core.Filter.process_commands ~with_test:true ~with_doc:true
      ~with_dev_setup:false pkg_scope commands
  in
  Fmt.pr "%a" Onix_core.Filter.pp_commands commands'

let process_depends depends =
  (* let depends_filtered_formula =
       OpamFilter.string_of_filtered_formula depends
     in *)
  let depends_ands : OpamTypes.filtered_formula list =
    OpamFormula.ands_to_list depends
  in
  let depends_ands_srs_list =
    List.map OpamFilter.string_of_filtered_formula depends_ands
  in

  Fmt.pr "%s" (String.concat ";; " depends_ands_srs_list)

let () = process_commands build_commands
