Ospecl is a library for writing executable specifications for your OCaml code à la rspec.

A spec is a data structure built up using calls to `describe` to provide context and `it` for executable examples. Expectations can be described by `expect`-ing a value to match a provided matcher. `expect` can also be used via its alias `=~`.

For example:

    describe "some component" [
      it "has some behaviour" begin
        expect my_component (has some_behaviour)
      end;
      describe "in some particular context" begin
        let different = in_context my_component in
        [
          it "has some different behaviour" begin
            expect different (has different_behaviour)
          end;
          it "does something else too" begin
            different =~ (does something_else)
          end
        ]
      end
    ]

A [working example](https://github.com/rapha/Ospecl/blob/master/examples/account_spec.ml) can be found in the examples directory, and another one [here](https://gist.github.com/896752#file_spec.ml).

Ospecl comes with a core set of matchers in `Ospecl.Matchers`, but you can define your own on top of `Ospecl.Matcher` that better describe your domain.

Specs may be executed using the command line runner:

    $ ospecl my_spec1.ml my_spec2.ml my_spec3.ml 
    
`ospecl` accepts a list of source files, each of which must define a single value, `specs`, with type `Spec.t list`. The specs from each of these files will be executed in order and the results reported together.

Ospecl also comes with runner functions `Ospecl.Run.console` and `Ospecl.Run.doc` which can be executed in your own script run from the command line. Additionally you can build altogether new runners by calling `Ospecl.Spec.Exec.execute` with your own set of handlers for the execution events.
