type t = {
  arch : string;
  os : string;
}

(* opam uses macos and arm64, while nix used darwin and aarch64 *)
let aarch64_linux = { arch = "arm64"; os = "linux" }
let aarch64_darwin = { arch = "arm64"; os = "macos" }
let x86_64_linux = { arch = "x86_64"; os = "linux" }
let x86_64_darwin = { arch = "x86_64"; os = "macos" }
let all = [aarch64_linux; aarch64_darwin; x86_64_darwin; x86_64_linux]
let os_list = ["linux"; "macos"]
let arch_list = ["x86_64"; "arm64"]

let host =
  let arch = OpamSysPoll.arch OpamVariable.Map.empty in
  let os = OpamSysPoll.os OpamVariable.Map.empty in
  match (arch, os) with
  | Some arch, Some os -> { arch; os }
  | Some _, None -> failwith "could not get host's 'os'"
  | None, Some _ -> failwith "could not get host's 'arch'"
  | None, None -> failwith "could not get host's 'arch' and 'os'"

let to_string t = String.concat "-" [t.arch; t.os]
let pp f x = Fmt.string f (to_string x)
