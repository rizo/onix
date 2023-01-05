open struct
  let join = String.concat "/"
end

let lib ?pkg_name ?subdir ~ocaml_version prefix =
  let pkg_name = Option.map OpamPackage.Name.to_string pkg_name in
  let ocaml_version = OpamPackage.Version.to_string ocaml_version in
  match (pkg_name, subdir) with
  | None, None -> join [prefix; "lib/ocaml"; ocaml_version; "site-lib"]
  | None, Some subdir ->
    join [prefix; "lib/ocaml"; ocaml_version; "site-lib"; subdir]
  | Some name, None ->
    join [prefix; "lib/ocaml"; ocaml_version; "site-lib"; name]
  | Some name, Some subdir ->
    join [prefix; "lib/ocaml"; ocaml_version; "site-lib"; subdir; name]

let stublibs ?pkg_name = lib ?pkg_name ~subdir:"stublibs"
let toplevel ?pkg_name = lib ?pkg_name ~subdir:"toplevel"

let out ?pkg_name ~subdir prefix =
  let pkg_name = Option.map OpamPackage.Name.to_string pkg_name in
  match pkg_name with
  | None -> join [prefix; subdir]
  | Some name -> join [prefix; subdir; name]

let bin = out ~subdir:"bin"
let sbin = out ~subdir:"sbin"
let share = out ~subdir:"share"
let etc = out ~subdir:"etc"
let doc = out ~subdir:"doc"
let man = out ?pkg_name:None ~subdir:"man"
