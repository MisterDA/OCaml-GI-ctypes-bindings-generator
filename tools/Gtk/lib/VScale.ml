open Ctypes
open Foreign

type t = unit ptr
let t_typ : t typ = ptr void

(*Not implemented gtk_vscale_new type object not implemented*)
(*Not implemented gtk_vscale_new_with_range return type object not handled*)