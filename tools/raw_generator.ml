module BG = GI_bindings_generator
module Loader = BG.Loader
module GI = GObject_introspection

let usage_msg =
  "raw_generator.exe <GObject Introspection namespace> [version number]"

let namespace = ref ""
let version = ref None

let () =
  let n = ref 0 in
  Arg.parse []
    (fun arg ->
      if !n = 0 then namespace := arg
      else if !n = 1 then version := Some arg
      else raise (Arg.Bad usage_msg);
      incr n)
    usage_msg;
  if !n < 1 then (
    prerr_endline usage_msg;
    exit 1)

let dest_dir = "./"
let sources = Loader.generate_files dest_dir "Core"

let get_data_structures_and_functions namespace ?version () =
  let open GI in
  match Repository.require namespace ?version () with
  | Error _message -> ([], [])
  | Ok _typelib ->
      let n = Repository.get_n_infos namespace in
      let rec get_names index data_structures functions =
        if index >= n then (data_structures, functions)
        else
          let info = Repository.get_info namespace index in
          match Base_info.get_name info with
          | Some name -> (
              match Base_info.get_type info with
              | Bindings.Base_info.Function ->
                  get_names (index + 1) data_structures (name :: functions)
              | Object | Boxed | Struct ->
                  get_names (index + 1) (name :: data_structures) functions
              | Enum | Flags | Constant | Union | Callback | Invalid | Value
              | Signal | Vfunc | Property | Field | Arg | Type | Unresolved
              | Invalid_0 | Interface ->
                  get_names (index + 1) data_structures functions)
          | None -> get_names (index + 1) data_structures functions
      in
      get_names 0 [] []

let () =
  let namespace = !namespace and version = !version in
  Loader.write_constant_bindings_for namespace ?version sources [];
  Loader.write_enum_and_flag_bindings_for namespace ?version dest_dir ();
  let data_structures, functions =
    get_data_structures_and_functions namespace ?version ()
  in
  Loader.write_function_bindings_for namespace ?version sources functions;
  Loader.write_bindings_for namespace ?version dest_dir data_structures;
  BG.Binding_utils.Sources.close sources
