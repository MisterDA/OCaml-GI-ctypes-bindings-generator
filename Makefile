all:
	dune build @all

.PHONY: coverage
coverage:
	BISECT_ENABLE=YES dune runtest
	bisect-ppx-report -html _coverage/bisect*.out

.PHONY: update_glib2_raw
update_glib2_raw:
	cd tools/GLib && dune exec -- ../raw_generator.exe GLib
	cp -rf tools/GLib/lib/* ../OCaml-GLib2/lib/

.PHONY: update_gtk3_raw
update_gtk3_raw:
	cd tools/Gtk3 && dune exec -- ../raw_generator.exe Gtk 3.0
	cp -rf tools/Gtk/lib/* ../OCaml-Gtk3/lib/

.PHONY: update_gio2_raw
update_gio2_raw:
	cd tools/Gio && dune exec -- ../raw_generator.exe Gio
	cp -rf tools/Gio/lib/* ../OCaml-Gio/lib/
