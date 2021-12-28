# TOOLS

## raw_generator.ml

It is a generic GObject-Introspection loader. It generates all the raw Ctypes
bindings of a given namespace library. It is used for testing purpose. A real
loader can be found here: <https://github.com/cedlemo/OCaml-GLib2>.

### Build

```
mkdir -p tools/GLib && cd tools/GLib
dune exec -- ../raw_generator.exe GLib
cd .. && mkdir -p tools/Gio && cd tools/Gio
dune exec -- ../raw_generator.exe Gio
cd .. && mkdir -p tools/Gtk3 && cd tools/Gtk3
dune exec -- ../raw_generator.exe Gtk 3.0
```
