all: test.byte
	ocamlrun -b test.byte && bash test_run.bash

test.byte: ospecl.cma test_matcher.ml test_specify.ml test_matchers.ml
	ocamlc -g ospecl.cma test_matcher.ml test_matchers.ml test_specify.ml -o test.byte

ospecl.cma: matcher.cmo matchers.cmo specify.cmo run.cmo
	ocamlc -g -linkall -pack -o ospecl.cma matcher.cmo matchers.cmo specify.cmo run.cmo

matcher.cmo: matcher.mli matcher.ml
	ocamlc -g -c matcher.mli matcher.ml

matchers.cmo: matchers.ml
	ocamlc -g -c matchers.ml

specify.cmo: specify.ml
	ocamlc -g -c specify.mli specify.ml

run.cmo: run.ml
	ocamlc -g -c run.ml

clean:
	rm *.cm* test.byte
