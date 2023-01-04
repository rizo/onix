val patch : Pkg_scope.t -> unit

val build :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Pkg_scope.t ->
  string list list

val install :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Pkg_scope.t ->
  string list list
