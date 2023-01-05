module Paths = struct
  open OpamFilename.Op

  let packages ~root = root / "packages"
  let package_versions ~root n = packages ~root / OpamPackage.Name.to_string n

  let package ~root nv =
    packages ~root / OpamPackage.name_to_string nv / OpamPackage.to_string nv

  let opam ~root nv = package ~root nv // "opam" |> OpamFile.make
  let files ~root nv = package ~root nv / "files"
end

type t = {
  root : OpamTypes.dirname;
  urls : OpamUrl.t list;
}

let make ~root ~urls = { root; urls }

let read_opam t nv =
  let path = Paths.opam ~root:t.root nv in
  OpamFile.OPAM.read path

let get_opam_filename t nv = Paths.opam ~root:t.root nv |> OpamFile.filename

let read_package_versions t name =
  let path = Paths.package_versions ~root:t.root name in
  Utils.Filesystem.fold_dir
    (fun acc subdir ->
      let nv = OpamPackage.of_string subdir in
      let v = OpamPackage.version nv in
      v :: acc)
    []
    (OpamFilename.Dir.to_string path)
