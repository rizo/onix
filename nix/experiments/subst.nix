let
  inherit (builtins) length toJSON elemAt isNull isList;
  trace = x: builtins.trace "onix: [TRACE] ${builtins.toJSON x}" x;
  debug = data: x: builtins.trace "onix: [DEBUG] ${builtins.toJSON data}" x;
in rec {
  # %{...}%
  split-file-content = content:
    builtins.split "%\\{([a-z0-9?:_-]+)\\}%" content;

  # scope:var?string-if-true:string-if-false-or-undefined
  split-full-var-cond = ful-var-cond:
    builtins.split "^([^:]+):?([^?]*)\\??([^:]*):?(.*)" ful-var-cond;

  # builtins.split ''^([^:]+):?([^?]*)\??([^:]*):?(.*)'' "ocaml-system:installed?yes:no"
  # => ["",["ocaml-system","installed","yes","no"],""]
  # => { scope = "package"; pkg-name = "ocaml-system"; var = "installed"; val-if-true = "yes"; val-if-false = "no"; }
  process-var = parts:
    if length parts != 3 then
      throw "Could not process subst variable: ${toJSON parts}"
    else
      let var-parts = elemAt parts 1;
      in if length var-parts != 4 then
        throw "Could not process subst variable: ${toJSON var-parts}"
      else
        let
          scope-or-var-name-part = elemAt var-parts 0;
          var-name-opt-part = elemAt var-parts 1;
          val-if-true-part = elemAt var-parts 2;
          val-if-false-part = elemAt var-parts 3;
        in rec {
          pkg-name =
            if var-name-opt-part != "" then scope-or-var-name-part else null;
          scope = if isNull pkg-name then
            "global"
          else if pkg-name == "_" then
            "self"
          else
            "package";
          var = if var-name-opt-part != "" then
            var-name-opt-part
          else
            scope-or-var-name-part;
          val-if-true =
            if val-if-true-part != "" then val-if-true-part else null;
          val-if-false =
            if val-if-false-part != "" then val-if-false-part else null;
        };

  subst-file-content = resolve: content:
    let
      is-var-part = builtins.isList;
      content-parts = split-file-content content;
      contents-resolved-parts = builtins.concatMap (part:
        # invalid var
        if isList part && length part != 1 then
          throw "could not process file subst var: ${toJSON part}"
        else
        # valid var
        if isList part then
          let
            full-var-cond-str = elemAt part 0;
            full-var-cond = split-full-var-cond full-var-cond-str;
            full-var = process-var full-var-cond;
            resolved = resolve full-var;
          in [ (if isNull resolved then "" else resolved) ]
        else
        # text
          [ part ]) content-parts;
    in builtins.concatStringsSep "" contents-resolved-parts;
}
