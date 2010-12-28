all: test.exe
	./test.exe

test.exe: ospecl.cmxa test.ml
	ocamlopt ospecl.cmxa test.ml -o test.exe

ospecl.cmxa: ospecl.mli ospecl.ml
	ocamlopt ospecl.mli ospecl.ml -a -o ospecl.cmxa

clean:
	rm *.cm* *.a *.o test.exe

