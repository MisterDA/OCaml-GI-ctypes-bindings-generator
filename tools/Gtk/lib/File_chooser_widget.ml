open Ctypes
open Foreign

type t = unit ptr
let t_typ : t typ = ptr void

(*Not implemented gtk_file_chooser_widget_new return type object not handled*)