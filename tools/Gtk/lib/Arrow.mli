open Ctypes

type t
val t_typ : t typ

(*Not implemented gtk_arrow_new return type object not handled*)
val set:
  t structure ptr -> Arrow_type.t -> Shadow_type.t -> unit