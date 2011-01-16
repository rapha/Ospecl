all: test.exe
	ocamlrun -b test.exe

test.exe: ospecl.cma matcher.cma test_matcher.ml test_ospecl.ml test_matchers.ml
	ocamlc -g matcher.cma ospecl.cma test_matcher.ml test_matchers.ml test_ospecl.ml -o test.exe

ospecl.cma: matcher.cma matchers.cma ospecl.mli ospecl.ml
	ocamlc -g matcher.cma matchers.cma ospecl.mli ospecl.ml -a -o ospecl.cma

matchers.cma: matcher.cma matchers.ml
	ocamlc -g matcher.cma matchers.ml -a -o matchers.cma

matcher.cma: matcher.ml
	ocamlc -g matcher.mli matcher.ml -a -o matcher.cma

clean:
	rm *.cm* *.a *.o test.exe

