GEN_FILES = *.cm* *.a *.o test

all: test
	./test

test: ospecl.cmxa test.ml
	ocamlopt ospecl.cmxa test.ml -o test

ospecl.cmxa: ospecl.mli ospecl.ml
	ocamlopt ospecl.mli ospecl.ml -a -o ospecl.cmxa

clean:
	rm $(GEN_FILES)

