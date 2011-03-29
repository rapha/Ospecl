all: test

test: unit_tests.byte
	ocamlrun -b unit_tests.byte && bash test_console.bash

unit_tests.byte: ospecl.cma test_matcher.cmo test_matchers.cmo test_run.cmo
	$(OCAMLC) -o unit_tests.byte unix.cma ospecl.cma test_matcher.cmo test_matchers.cmo test_run.cmo

ospecl.cma: matcher.cmo matchers.cmo specify.cmo run.cmo
	$(OCAMLC) -pack -o ospecl.cma matcher.cmo matchers.cmo specify.cmo run.cmo

clean:
	rm *.cm* *.byte Makefile.source_dependencies

install: ospecl.cma META
	ocamlfind install ospecl ospecl.cmi ospecl.cma META

uninstall:
	ocamlfind remove ospecl


# simple file transforms
.SUFFIXES: .mli .ml .cmi .cmo
.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmo:
	$(OCAMLC) -c str.cma unix.cma $<

# autogenerate source dependencies
Makefile.source_dependencies: *.ml *.mli
	ocamldep *.ml *.mli >Makefile.source_dependencies
include Makefile.source_dependencies

# these targets are not files
.PHONY: all clean test

# definitions
OCAMLC = ocamlc -g -warn-error A
