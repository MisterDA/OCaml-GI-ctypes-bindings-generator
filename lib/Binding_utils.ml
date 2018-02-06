(*
 * Copyright 2017 Cedric LE MOIGNE, cedlemo@gmx.com
 * This file is part of OCaml-GObject-Introspection.
 *
 * OCaml-GObject-Introspection is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * OCaml-GObject-Introspection is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OCaml-GObject-Introspection.  If not, see <http://www.gnu.org/licenses/>.
 *)

open GObject_introspection

module Option = struct
  let value ~default value_or_none =
    match value_or_none with
      | None -> default
      | Some v -> v
end

let escape_OCaml_keywords variable_name =
  match variable_name with
  | "and"
  | "as"
  | "asr"
  | "assert"
  | "begin"
  | "class"
  | "constraint"
  | "do"
  | "done"
  | "downto"
  | "else"
  | "end"
  | "exception"
  | "external"
  | "false"
  | "for"
  | "fun"
  | "function"
  | "functor"
  | "if"
  | "in"
  | "include"
  | "inherit"
  | "inherit!"
  | "initializer"
  | "land"
  | "lazy"
  | "let"
  | "lor"
  | "lsl"
  | "lsr"
  | "lxor"
  | "match"
  | "method"
  | "method!"
  | "mod"
  | "module"
  | "mutable"
  | "nonrec"
  | "object"
  | "of"
  | "open"
  | "open!"
  | "or"
  | "private"
  | "rec"
  | "sig"
  | "struct"
  | "then"
  | "to"
  | "true"
  | "try"
  | "type"
  | "val"
  | "val!"
  | "virtual"
  | "when"
  | "while"
  | "with" -> "_" ^ variable_name
  | "new" -> "create"
  | "ref" -> "incr_ref"
  | _ -> variable_name

let has_number_at_beginning variable_name =
  let pattern = Str.regexp "[0-9].*" in
  Str.string_match pattern variable_name 0

let escape_number_at_beginning variable_name =
  if has_number_at_beginning variable_name then "_" ^ variable_name
  else variable_name

let escape_OCaml_types name =
  match name with
  | "int"
  | "float"
  | "list"
  | "string"
  | "char"
  | "array" -> "_" ^ name
  | _ -> name

(* Taken from https://realworldocaml.org/v1/en/html/foreign-function-interface.html. *)
let escape_Ctypes_types name =
  match name with
  | "void"
  | "char"
  | "schar"
  | "short"
  | "int"
  | "long"
  | "llong"
  | "nativeint"
  | "int8_t"
  | "int16_t"
  | "int32_t"
  | "int64_t"
  | "uchar"
  | "uint8_t"
  | "uint16_t"
  | "uint32_t"
  | "uint64_t"
  | "size_t"
  | "ushort"
  | "uint"
  | "ulong"
  | "ullong"
  | "float"
  | "double"
  | "complex32"
  | "complex64" -> "_" ^ name
  | _ -> name

let escape_new_pattern name =
  let pattern = Str.regexp "^new_\\(.*\\)" in
  let name = Str.global_replace pattern "create_\\1" name in
  let pattern = Str.regexp "\\(.*\\)_new$" in
  let name = Str.global_replace pattern "\\1_create" name in
  let pattern = Str.regexp "\\(.*\\)_new_\\(.*\\)" in
  Str.global_replace pattern "\\1_create_\\2" name

let ensure_valid_variable_name name =
  escape_OCaml_keywords name
  |> escape_OCaml_types
  |> escape_Ctypes_types
  |> escape_number_at_beginning
  |> escape_new_pattern

let generate_n_meaningless_arg_names n =
  if n < 0 then ""
  else
    let rec build n acc =
      match n with
      | 0 -> acc
      | _ -> build (n - 1) (("arg" ^ (string_of_int n)) :: acc)
    in
    String.concat " " (build n [])

let get_binding_name info =
  match Base_info.get_name info with
  | None -> None
  | Some name ->
    let bindings_name = Lexer.snake_case name in
    Some bindings_name

let string_pattern_remove str pattern =
  let reg = Str.regexp_string pattern in
  String.concat "" (Str.split reg str)

let match_one_of str patterns =
  let found pattern =
    let r = Str.regexp pattern in
    Str.string_match r str 0
  in
  let rec iterate = function
    | [] -> false
    | hd :: tl -> if found hd then true
                  else iterate tl
  in
  iterate patterns

module File = struct
  type t = {name : string; descr : Pervasives.out_channel; buffer : Buffer.t}

  let create name =
    let flags = [Open_trunc; Open_append; Open_creat] in
    let perm = 0o666 in
    let descr = Pervasives.open_out_gen flags perm name in
    let buffer = Buffer.create 16 in
    {name; descr; buffer}

  let create_tmp (name, descr) =
    let buffer = Buffer.create 16 in
    {name; descr; buffer}

  let close t =
    if Sys.file_exists t.name then (
      Pervasives.close_out t.descr;
      Buffer.reset t.buffer)

  let name t =
    t.name

  let descr t =
    t.descr

  let buffer t =
    t.buffer

  let write_open_module t module_name =
    Printf.fprintf t.descr "open %s\n" module_name

  let add_open_ctypes t =
    write_open_module t "Ctypes"

  let add_open_foreign t =
    write_open_module t "Foreign"

  let add_empty_line t =
    Printf.fprintf t.descr "%s" "\n"

  let add_comments t information =
    Printf.fprintf t.descr "(* %s. *)\n" information

  let buff_add t str =
    Buffer.add_string t.buffer str

  let buff_add_line t str =
    Buffer.add_string t.buffer str;
    Buffer.add_string t.buffer "\n"

  let buff_add_comments t str =
    Buffer.add_string t.buffer "(*";
    Buffer.add_string t.buffer str;
    Buffer.add_string t.buffer "*)\n"

  let buff_add_eol t =
    Buffer.add_string t.buffer "\n"

  let bprintf t =
    Printf.bprintf t.buffer

  let buff_write t =
    Buffer.output_buffer t.descr t.buffer;
    Buffer.clear t.buffer
end

module Sources = struct
  type t = {
    ml : File.t;
    mli : File.t;
  }

  let create name =
    let ml = File.create @@ name ^ ".ml" in
    let mli = File.create @@ name ^ ".mli" in
    {ml; mli}

  let create_ctypes base_name =
    let sources = create base_name in
    let _ = File.add_open_ctypes sources.mli in
    let _ = File.add_empty_line sources.mli in
    let _ = File.add_open_ctypes sources.ml in
    let _ = File.add_open_foreign sources.ml in
    let _ = File.add_empty_line sources.ml in
    sources

  let create_tmp (ml, mli) =
    {ml; mli}

  let ml t =
    t.ml

  let mli t =
    t.mli

  let write_buffs t =
    File.buff_write t.ml;
    File.buff_write t.mli

  let close t =
    let _ = File.close t.mli in
    File.close t.ml

  let buffs_add_comments t str =
    File.buff_add_comments t.mli str;
    File.buff_add_comments t.ml str

  let buffs_add_todo t str =
    let com = "TODO : " ^ str in
    File.buff_add_comments t.mli com;
    File.buff_add_comments t.ml com

  let buffs_add_deprecated t str =
    let com = "DEPRECATED : " ^ str in
    File.buff_add_comments t.mli com;
    File.buff_add_comments t.ml com

  let buffs_add_skipped t str =
    let com = "SKIPPED : " ^ str in
    File.buff_add_comments t.mli com;
    File.buff_add_comments t.ml com

  let buffs_add_eol t =
    File.buff_add_eol t.mli;
    File.buff_add_eol t.ml
end

type type_strings = { ocaml : string;
                      ctypes : string }

type bindings_types = Not_implemented of string | Types of type_strings

let type_tag_to_bindings_types = function
  | Types.Void -> Types { ocaml = "unit"; ctypes = "void" }
  | Types.Boolean -> Types { ocaml = "bool"; ctypes = "bool"}
  | Types.Int8 -> Types { ocaml = "int"; ctypes = "int8_t"}
  | Types.Uint8 -> Types { ocaml = "Unsigned.uint8"; ctypes = "uint8_t"}
  | Types.Int16 -> Types { ocaml = "int"; ctypes = "int16_t"}
  | Types.Uint16 -> Types { ocaml = "Unsigned.uint16"; ctypes = "uint16_t"}
  | Types.Int32 -> Types { ocaml = "int32"; ctypes = "int32_t"}
  | Types.Uint32 -> Types { ocaml = "Unsigned.uint32"; ctypes = "uint32_t"}
  | Types.Int64 -> Types { ocaml = "int64"; ctypes = "int64_t"}
  | Types.Uint64 -> Types { ocaml = "Unsigned.uint64"; ctypes = "uint64_t"}
  | Types.Float -> Types { ocaml = "float"; ctypes = "float"}
  | Types.Double -> Types { ocaml = "float"; ctypes = "double"}
  | Types.GType as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.Utf8 as tag-> Not_implemented (Types.string_of_tag tag)
  | Types.Filename as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.Array as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.Interface as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.GList as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.GSList as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.GHash as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.Error as tag -> Not_implemented (Types.string_of_tag tag)
  | Types.Unichar as tag -> Not_implemented (Types.string_of_tag tag)

let type_info_to_bindings_types type_info maybe_null =
  let check_if_pointer (ocaml_t, ctypes_t) =
    if Type_info.is_pointer type_info then
      if maybe_null then {ocaml = ocaml_t ^ " ptr option";
                          ctypes = "ptr_opt " ^ ctypes_t}
      else {ocaml = ocaml_t ^ " ptr";
            ctypes = "ptr " ^ ctypes_t}
    else {ocaml = ocaml_t; ctypes = ctypes_t}
  in
  match Type_info.get_interface type_info with
  | None -> (
    match Type_info.get_tag type_info with
    | Types.Void -> Types (check_if_pointer ("unit", "void"))
    | Types.Boolean -> Types (check_if_pointer ("bool", "bool"))
    | Types.Int8 -> Types (check_if_pointer ("int", "int8_t"))
    | Types.Uint8 -> Types (check_if_pointer ("Unsigned.uint8", "uint8_t"))
    | Types.Int16 -> Types (check_if_pointer ("int", "int16_t"))
    | Types.Uint16 -> Types (check_if_pointer ("Unsigned.uint16", "uint16_t"))
    | Types.Int32 -> Types (check_if_pointer ("int32", "int32_t"))
    | Types.Uint32 -> Types (check_if_pointer ("Unsigned.uint32", "uint32_t"))
    | Types.Int64 -> Types (check_if_pointer ("int64", "int64_t"))
    | Types.Uint64 -> Types (check_if_pointer ("Unsigned.uint64", "uint64_t"))
    | Types.Float -> Types (check_if_pointer ("float", "float"))
    | Types.Double -> Types (check_if_pointer ("float", "double"))
    | Types.GType as tag -> Not_implemented (Types.string_of_tag tag)
    | Types.Utf8 -> if maybe_null then Types {ocaml = "string option";
                                                ctypes = "string_opt"}
      else Types {ocaml = "string"; ctypes = "string"}
    | Types.Filename -> if maybe_null then Types {ocaml = "string option";
                                                    ctypes = "string_opt"}
      else Types {ocaml = "string"; ctypes = "string"}
    | Types.Array -> (
      match Type_info.get_array_type type_info with
      | None -> Not_implemented ("Bad Array type for Types.Array tag")
      | Some array_type ->
        match array_type with
        | Types.C -> Not_implemented ("C Array type for Types.Array tag")
        | Types.Array -> Types (check_if_pointer ("Array.t structure", "Array.t_typ"))
        | Types.Ptr_array -> Types (check_if_pointer ("Ptr_array.t structure", "Ptr_array.t_typ"))
        | Types.Byte_array -> Types (check_if_pointer ("Byte_array.t structure", "Byte_array.t_typ"))
      )
    | Types.Interface as tag -> Not_implemented (Types.string_of_tag tag)
    | Types.GList -> Types (check_if_pointer ("List.t structure", "List.t_typ"))
    | Types.GSList -> Types (check_if_pointer ("SList.t structure", "SList.t_typ"))
    | Types.GHash -> Types (check_if_pointer ("Hash_table.t structure", "Hash_table.t_typ"))
    | Types.Error -> Types (check_if_pointer ("Error.t structure", "Error.t_typ"))
    | Types.Unichar as tag -> Not_implemented (Types.string_of_tag tag)
    )
  | Some interface ->
      match Base_info.get_type interface with
      | Invalid as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Function as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Callback as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Struct as t -> (
        match get_binding_name interface with
        | None -> Not_implemented (Base_info.string_of_baseinfo_type t)
        | Some name ->
        Types (check_if_pointer (Printf.sprintf "%s.t structure" name, Printf.sprintf "%s.t_typ" name))
      )
      | Boxed as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Enum as t -> (
        match get_binding_name interface with
        | None -> Not_implemented (Base_info.string_of_baseinfo_type t)
        | Some name ->
        Types {ocaml = Printf.sprintf "%s.t" name; ctypes = Printf.sprintf "%s.t_view" name}
      )
      | Flags as t -> (
        match get_binding_name interface with
        | None -> Not_implemented (Base_info.string_of_baseinfo_type t)
        | Some name ->
        Types {ocaml = Printf.sprintf "%s.t_list" name; ctypes = Printf.sprintf "%s.t_list_view" name}
      )
      | Object as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Interface as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Constant as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Invalid_0 as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Union as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Value as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Signal as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Vfunc as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Property as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Field as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Arg as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Type as t -> Not_implemented (Base_info.string_of_baseinfo_type t)
      | Unresolved as t -> Not_implemented (Base_info.string_of_baseinfo_type t)

let allocate_type_bindings type_info var_name maybe_null =
  let _get_allocate_type_and_def_value () =
    let check_if_pointer (ctypes_t, default_value) =
      (* Consider that a pointer can always be null no need to check for maybe_null. *)
      if Type_info.is_pointer type_info then
        (Printf.sprintf "(ptr_opt %s)" ctypes_t,
         "None",
         Printf.sprintf "!@ %s_ptr" var_name)
      else (ctypes_t, default_value, Printf.sprintf "!@ %s_ptr" var_name)
    in
    match Type_info.get_interface type_info with
    | None -> (
      match Type_info.get_tag type_info with
      | Types.Void -> Some (check_if_pointer ("void", "None"))
      | Types.Boolean -> Some (check_if_pointer ("bool", "false"))
      | Types.Int8 -> Some (check_if_pointer ("int8_t", "0"))
      | Types.Uint8 -> Some (check_if_pointer ("uint8_t", "Unsigned.UInt8.zero"))
      | Types.Int16 -> Some (check_if_pointer ("int16_t", "0"))
      | Types.Uint16 -> Some (check_if_pointer ("uint16_t", "Unsigned.UInt16.zero"))
      | Types.Int32 -> Some (check_if_pointer ("int32_t", "Int32.zero"))
      | Types.Uint32 -> Some (check_if_pointer ("uint32_t", "Unsigned.UInt32.zero"))
      | Types.Int64 -> Some (check_if_pointer ("int64_t", "Int64.zero"))
      | Types.Uint64 -> Some (check_if_pointer ("uint64_t", "Unsigned.UInt64.zero"))
      | Types.Float -> Some (check_if_pointer ("float", "0.0"))
      | Types.Double -> Some (check_if_pointer ("double", "0.0"))
      | Types.GType -> None
      | Types.Utf8 | Types.Filename -> begin
          if maybe_null then
            Some ("string_opt",
                  "None",
                  Printf.sprintf "!@ %s_ptr" var_name)
          else
              Some ("string", "\" \"", Printf.sprintf "!@ %s_ptr" var_name)
      end
      | Types.Array -> None
      | Types.Interface -> None
      | Types.GList -> Some (check_if_pointer ("List.t_typ", "None"))
      | Types.GSList -> Some (check_if_pointer ("SList.t_typ", "None"))
      | Types.GHash -> Some (check_if_pointer ("Hash_table.t_typ", "None"))
      | Types.Error -> Some (check_if_pointer ("Error.t_typ", "None"))
      | Types.Unichar -> None
      )
    | Some interface ->
        match Base_info.get_type interface with
        | Invalid | Function | Callback | Boxed | Enum | Flags -> None
        | Struct -> (
          match get_binding_name interface with
          | None -> None
          | Some name ->
          Some (check_if_pointer ((Printf.sprintf "%s.t_typ" name), "None"))
        )
        | Object | Interface | Constant | Invalid_0 | Union | Value | Signal
        | Vfunc | Property | Field | Arg | Type | Unresolved -> None
  in
  match _get_allocate_type_and_def_value () with
  | None -> None
  | Some (t, v, r) ->
      let allocate_instructions =
        Printf.sprintf "let %s_ptr = allocate %s %s in\n" var_name t v in
      let get_value = Printf.sprintf "%s" r in
      Some (allocate_instructions, get_value)
