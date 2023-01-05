open Onix_core
open Onix_core.Utils

let install_phase_str_for_install_files ~ocaml_version =
  Fmt.str
    {|

  ${nixpkgs.opaline}/bin/opaline \
    -prefix="$out" \
    -libdir="$out/lib/ocaml/%s/site-lib"|}
    (OpamPackage.Version.to_string ocaml_version)

let install_phase_str_for_config_files ~package_name =
  Fmt.str
    {|
  if [[ -e "./%s.config" ]]; then
    mkdir -p "$out/etc"
    cp "./%s.config" "$out/etc/%s.config"
  fi|}
    (OpamPackage.Name.to_string package_name)
    (OpamPackage.Name.to_string package_name)
    (OpamPackage.Name.to_string package_name)

let pp_string_escape_with_enderscore formatter str =
  if Utils.String.starts_with_number str then Fmt.string formatter ("_" ^ str)
  else Fmt.string formatter str

let pp_name_escape_with_enderscore formatter name =
  let name = OpamPackage.Name.to_string name in
  pp_string_escape_with_enderscore formatter name

let pp_string_escape_quotted formatter str =
  if Utils.String.starts_with_number str then Fmt.Dump.string formatter str
  else Fmt.string formatter str

let pp_version f version =
  let version = OpamPackage.Version.to_string version in
  (* We require that the version does NOT contain any '-' or '~' characters.
     - Note that nix will replace '~' to '-' automatically.
     The version is parsed with Nix_utils.parse_store_path by splitting bytes
     '- ' to obtain the Pkg_scope.package information.
     This is fine because the version in the lock file is mostly informative. *)
  let set_valid_char i =
    match String.get version i with
    | '-' | '~' -> '+'
    | valid -> valid
  in
  let version = String.init (String.length version) set_valid_char in
  Fmt.pf f "%S" version

let pp_hash f (kind, hash) =
  match kind with
  | `SHA256 -> Fmt.pf f "sha256 = %S" hash
  | `SHA512 -> Fmt.pf f "sha512 = %S" hash
  | `MD5 -> Fmt.pf f "md5 = %S" hash

let pp_src ~gitignore f (t : Lock_pkg.t) =
  if Opam_utils.Opam_details.check_has_absolute_path t.opam_details then
    match t.src with
    | None -> Fmt.pf f "@,src = null;@,dontUnpack = true;"
    | Some (Git { url; rev }) ->
      Fmt.pf f
        "@,\
         src = @[<v-4>builtins.fetchGit {@ url = %S;@ rev = %S;@ allRefs = \
         true;@]@ };"
        url rev
    (* MD5 hashes are not supported by Nix fetchers. Fetch without hash.
       This normally would not happen as we try to prefetch_src_if_md5. *)
    | Some (Http { url; hash = `MD5, _ }) ->
      Logs.warn (fun log ->
          log "Ignoring hash for %a. MD5 hashes are not supported by nix."
            Opam_utils.pp_package t.opam_details.package);
      Fmt.pf f "@,src = @[<v-4>fetchurl {@ url = %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url
    | Some (Http { url; hash }) ->
      Fmt.pf f "@,src = @[<v-4>nixpkgs.fetchurl {@ url = %a;@ %a;@]@ };"
        (Fmt.quote Opam_utils.pp_url)
        url pp_hash hash
  else
    let path =
      let opam_path = t.opam_details.Opam_utils.path in
      let path = OpamFilename.(Dir.to_string (dirname opam_path)) in
      if String.equal path "." then "./../../.." else path
    in
    if gitignore then
      Fmt.pf f "@,src = nixpkgs.nix-gitignore.gitignoreSource [] %s;" path
    else Fmt.pf f "@,src = ./../../..;"

let pp_depends_sets name f req =
  let pp_req f =
    String_set.iter (fun dep ->
        Fmt.pf f "@ %a" pp_string_escape_with_enderscore dep)
  in
  if String_set.is_empty req then ()
  else Fmt.pf f "@ %s = [@[<hov1>%a@ @]];" name pp_req req

let pp_phase_commands =
  Fmt.list ~sep:Fmt.cut (Fmt.using Utils.command_to_string Fmt.string)

let pp_phase name f commands =
  if List.is_empty commands then Fmt.pf f "@,%s = \"true\";" name
  else Fmt.pf f "@,@[<v2>%s = ''@,%a@]@,'';" name pp_phase_commands commands

let pp_install_phase ~package_name ~ocaml_version f commands =
  if List.is_empty commands then ()
  else
    Fmt.pf f "@,@[<v2>installPhase = ''@,%a%s@,%s@]@,'';" pp_phase_commands
      commands
      (install_phase_str_for_install_files ~ocaml_version)
      (install_phase_str_for_config_files ~package_name)

let pp_file_inputs f inputs =
  let pp_inputs =
    Fmt.iter ~sep:Fmt.comma String_set.iter pp_string_escape_with_enderscore
  in
  Fmt.pf f "@[<hov2>{ %a@] }" pp_inputs inputs

let pp_ocamlfind_setup_hook f setup_hook =
  match setup_hook with
  | None -> ()
  | Some setup_hook ->
    Fmt.pf f {|@,setupHook = writeText "setup-hook.sh" ''%s  '';|} setup_hook

let pp_patches f patches =
  if List.is_empty patches then ()
  else
    let paths =
      List.map (fun base -> "./" ^ OpamFilename.Base.to_string base) patches
    in
    Fmt.pf f {|@,@[<v2>patches = [@,%a@]@,];|} (Fmt.list Fmt.string) paths

(* Printers for the nix commands with filters. *)

let pp_with_filter pp_v f (v, filter) =
  Fmt.pf f "@[<v2>(when (%s) %a)@]"
    (Nix_filter.opam_filter_to_nix_string filter)
    pp_v v

let pp_command f (command : string list * OpamTypes.filter option) =
  match command with
  | args_str, None ->
    Fmt.pf f "[ %a ]" (Fmt.using command_to_string Fmt.string) args_str
  | args_str, Some filter ->
    Fmt.pf f "@[<v2>(when (%s) [ %a ]@])"
      (Nix_filter.opam_filter_to_nix_string filter)
      (Fmt.using command_to_string Fmt.string)
      args_str

let pp_commands f (commands : (string list * OpamTypes.filter option) list) =
  if List.is_empty commands then ()
  else
    Fmt.pf f "@,@[<v2>build = with onix.vars; [@,%a@]@,];" (Fmt.list pp_command)
      commands

(* Package printer *)

let pp_pkg ~gitignore f (nix_pkg : Nix_pkg.t) =
  let lock_pkg = nix_pkg.lock_pkg in
  let name = OpamPackage.name_to_string lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  Format.fprintf f
    "%a:@.@.@[<v2>nixpkgs.stdenv.mkDerivation {@ pname = %S;@ version = \
     %a;%a%a@,\
     %a@,\
     %a%a%a%a@]@ }@." (* inputs *) pp_file_inputs nix_pkg.inputs
    (* name and version *) name pp_version version
    (* src *)
    (pp_src ~gitignore)
    lock_pkg (* patches *)
    pp_patches nix_pkg.patches
    (* propagatedBuildInputs *)
    (pp_depends_sets "propagatedBuildInputs")
    nix_pkg.propagated_build_inputs
    (* propagatedNativeBuildInputs *)
    (pp_depends_sets "propagatedNativeBuildInputs")
    nix_pkg.propagated_native_build_inputs
    (* checkInputs *)
    (pp_depends_sets "checkInputs")
    nix_pkg.check_inputs (* build *) pp_commands nix_pkg.build
    (* installPhase *)
    (pp_install_phase
       ~package_name:(OpamPackage.name lock_pkg.opam_details.package)
       ~ocaml_version:(OpamPackage.Version.of_string "4.14.0"))
    nix_pkg.install_phase

(* Lock file printers *)

let pp_version f version = Fmt.pf f "version = %S;" version

let pp_repo_uri f repo_url =
  match repo_url.OpamUrl.hash with
  | Some rev ->
    Fmt.pf f "@[<v2>repo = builtins.fetchGit {@ url = %a;@ rev = %S;@]@,};"
      (Fmt.quote Opam_utils.pp_url)
      { repo_url with OpamUrl.hash = None }
      rev
  | None ->
    Fmt.invalid_arg "Repo URI without fragment: %a" Opam_utils.pp_url repo_url

let pp_index_pkg formatter (lock_pkg : Lock_pkg.t) =
  let name_str = OpamPackage.name_to_string lock_pkg.opam_details.package in
  let version = OpamPackage.version lock_pkg.opam_details.package in
  match name_str with
  | "ocaml-system" ->
    let nixpkgs_ocaml = Nix_utils.make_ocaml_packages_path version in
    Fmt.pf formatter "\"ocaml-system\" = nixpkgs.%s;" nixpkgs_ocaml
  | _ ->
    Fmt.pf formatter "%S = self.callPackage ./packages/%s { };" name_str
      name_str

let pp_index f lock_pkgs =
  Fmt.pf f
    {|{ nixpkgs ? import <nixpkgs> { }, overlay ? import ./overlay nixpkgs }:

let
newScope = onixpkgs:
  nixpkgs.lib.callPackageWith ({ inherit nixpkgs; } // onixpkgs);

packages = nixpkgs.lib.makeScope newScope (self: {@[<v4>    %a@]@,});

in packages.overrideScope' overlay@.|}
    Fmt.(list ~sep:cut pp_index_pkg)
    lock_pkgs
