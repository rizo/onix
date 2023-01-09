type t = {
  arch : string;
  os : string;
}

(* opam uses macos and arm64, while nix used darwin and aarch64 *)
let aarch64_linux = { arch = "arm64"; os = "linux" }
let aarch64_darwin = { arch = "arm64"; os = "macos" }
let x86_64_darwin = { arch = "x86_64"; os = "macos" }
let x86_64_linux = { arch = "x86_64"; os = "linux" }

let host =
  let arch = OpamSysPoll.arch () in
  let os = OpamSysPoll.os () in
  match (arch, os) with
  | Some arch, Some os -> { arch; os }
  | Some _, None -> failwith "could not get host's 'os'"
  | None, Some _ -> failwith "could not get host's 'arch'"
  | None, None -> failwith "could not get host's 'arch' and 'os'"