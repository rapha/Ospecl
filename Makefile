all: test.exe
	./test.exe

test.exe: ospecl.cma test.ml
	ocamlc ospecl.cma test.ml -o test.exe

ospecl.cma: ospecl.mli ospecl.ml
	ocamlc ospecl.mli ospecl.ml -a -o ospecl.cma

ospecl.cmxa: ospecl.mli ospecl.ml
	ocamlopt ospecl.mli ospecl.ml -a -o ospecl.cmxa

clean:
	rm *.cm* *.a *.o test.exe

