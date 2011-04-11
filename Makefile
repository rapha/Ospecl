all: test

test: unit_tests.byte
	ocamlrun -b unit_tests.byte && bash test/test_console.bash

unit_tests.byte: ospecl.cma test/test_matcher.cmo test/test_matchers.cmo test/test_spec.cmo test/test_run.cmo
	$(OCAMLC) -o unit_tests.byte unix.cma ospecl.cma test/test_matcher.cmo test/test_matchers.cmo test/test_spec.cmo test/test_run.cmo

examples: ospecl.cma examples/account.cmo examples/account_spec.ml
	./ospecl examples/account_spec.ml

ospecl.cma: src/matcher.cmo src/matchers.cmo src/spec.cmo src/run.cmo
	$(OCAMLC) -pack -o ospecl.cma src/matcher.cmo src/matchers.cmo src/spec.cmo src/run.cmo

clean:
	find -E . -regex '.*\.(cm.|byte|source_dependencies)' | xargs rm

install: ospecl.cma META
	ocamlfind install ospecl ospecl.cmi ospecl.cma META

uninstall:
	ocamlfind remove ospecl


# simple file transforms
.SUFFIXES: .mli .ml .cmi .cmo
.mli.cmi:
	$(OCAMLC) -c -I src $<
.ml.cmo:
	$(OCAMLC) -c str.cma unix.cma -I src $<

# autogenerate source dependencies
Makefile.source_dependencies: src/*.mli src/*.ml
	ocamldep src/*.mli src/*.ml >Makefile.source_dependencies
include Makefile.source_dependencies

# these targets are not files
.PHONY: all clean test examples

# definitions
OCAMLC = ocamlc -g -warn-error A
