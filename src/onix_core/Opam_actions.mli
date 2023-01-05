val patch : Scope.t -> unit

val build :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Scope.t ->
  string list list

val install :
  with_test:bool ->
  with_doc:bool ->
  with_dev_setup:bool ->
  Scope.t ->
  string list list
