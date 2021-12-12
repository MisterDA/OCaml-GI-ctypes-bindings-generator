(lang dune 2.9)
(formatting disabled)
(name gi-bindings-generator)
(generate_opam_files true)
(source (github cedlemo/OCaml-GI-ctypes-bindings-generator))
(authors "Cédric Le Moigne <cedlemo@gmx.com>")
(maintainers "Cédric Le Moigne <cedlemo@gmx.com>")
(license "GPL-3.0-or-later")
(documentation https://github.com/cedlemo/OCaml-GI-ctypes-bindings-generator/wiki)
(package
 (name gi-bindings-generator)
 (synopsis "A GObject-Introspection Ctypes bindings generator library")
 (depends
  ctypes
  ctypes-foreign
  gobject-introspection
  (ounit2 :with-test)
  (bisect_ppx (and :build (>= 1.3.0)))))
