val patch : Pkg_ctx.t -> unit

val build :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Pkg_ctx.t ->
  string list list

val install :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Pkg_ctx.t ->
  string list list
