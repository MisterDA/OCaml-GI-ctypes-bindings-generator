open Ctypes

type t
val t_typ : t typ

val get_child :
  t -> Widget.t
