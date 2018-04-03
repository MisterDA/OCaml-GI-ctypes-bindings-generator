open Ctypes

type t
val t_typ : t typ

val create :
  unit -> t
val apply_default_background :
  t -> Context.t structure ptr -> Window.t -> State_type.t -> int32 -> int32 -> int32 -> int32 -> unit
val copy :
  t -> t
val detach :
  t -> unit
(*Not implemented gtk_style_get_style_property type gType not implemented*)
val has_context :
  t -> bool
val lookup_color :
  t -> string -> (bool * Color.t structure)
val lookup_icon_set :
  t -> string -> Icon_set.t structure ptr
val render_icon :
  t -> Icon_source.t structure ptr -> Text_direction.t -> State_type.t -> int32 -> Widget.t -> string option -> Pixbuf.t
val set_background :
  t -> Window.t -> State_type.t -> unit
