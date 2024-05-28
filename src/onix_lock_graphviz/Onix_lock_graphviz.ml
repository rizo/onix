module String_set = Onix_core.Utils.String_set
module Name_map = Onix_core.Utils.Name_map
module Name_set = Onix_core.Utils.Name_set
open Onix_core

let get_lock_pkg_name (lock_pkg : Lock_pkg.t) =
  lock_pkg.opam_details.package.name

let to_map lock_pkgs =
  List.fold_left
    (fun acc (lock_pkg : Lock_pkg.t) ->
      let name = get_lock_pkg_name lock_pkg in
      Name_map.add name lock_pkg acc)
    Name_map.empty lock_pkgs

let pp ppf (pkgs : Lock_pkg.t Name_map.t) =
  Fmt.pf ppf "digraph deps {@.";
  Name_map.iter
    (fun name (lock_pkg : Lock_pkg.t) ->
      let str = OpamPackage.Name.to_string in
      let name = OpamPackage.Name.to_string name in
      (* depends *)
      Name_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S;@." name (str dep))
        lock_pkg.depends;
      (* depends_build *)
      Name_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"red\"];@." name (str dep))
        lock_pkg.depends_build;
      (* depends_test *)
      Name_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"blue\"];@." name (str dep))
        lock_pkg.depends_test;
      (* depends_doc *)
      Name_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"green\"];@." name (str dep))
        lock_pkg.depends_doc;
      (* depends_dev_setup *)
      Name_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"yellow\"];@." name (str dep))
        lock_pkg.depends_dev_setup;
      (* depexts_nix *)
      String_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"grey\"];@." name dep)
        lock_pkg.depexts_nix;
      (* depeexts_unknown *)
      String_set.iter
        (fun dep -> Fmt.pf ppf "%S -> %S [color=\"grey\"];@." name dep)
        lock_pkg.depexts_unknown)
    pkgs;
  Fmt.pf ppf "}@."

let gen ~graphviz_file_path (lock_file : Lock_file.t) =
  let pkgs = to_map lock_file.packages in
  Onix_core.Utils.Out_channel.with_open_text graphviz_file_path (fun chan ->
      let out = Format.formatter_of_out_channel chan in
      Fmt.pf out "%a" pp pkgs);
  Logs.info (fun log ->
      log "Created an graphviz file at %S." graphviz_file_path)
