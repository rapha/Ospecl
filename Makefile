all: test

test: test.byte
	ocamlrun -b test.byte && bash test_run.bash

test.byte: ospecl.cma test_matcher.cmo test_specify.cmo test_matchers.cmo
	$(OCAMLC) -o test.byte unix.cma ospecl.cma test_matcher.cmo test_matchers.cmo test_specify.cmo

ospecl.cma: matcher.cmo matchers.cmo specify.cmo run.cmo
	$(OCAMLC) -pack -o ospecl.cma matcher.cmo matchers.cmo specify.cmo run.cmo

clean:
	rm *.cm* test.byte Makefile.source_dependencies

install: ospecl.cma META
	ocamlfind install ospecl ospecl.cmi ospecl.cma META

uninstall:
	ocamlfind remove ospecl


# simple file transforms
.SUFFIXES: .mli .ml .cmi .cmo
.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmo:
	$(OCAMLC) -c unix.cma $<

# autogenerate source dependencies
Makefile.source_dependencies: *.ml *.mli
	ocamldep *.ml *.mli >Makefile.source_dependencies
include Makefile.source_dependencies

# these targets are not files
.PHONY: all clean test

# definitions
OCAMLC = ocamlc -g -warn-error A
