Ospecl is a library that allows you to write executable specifications for your OCaml code à la rspec.

A spec is a data structure built up using calls to `describe` to provide context and `it` for executable examples. Expectations can be described by `expect`-ing a value to match a provided matcher. `expect` can also be used via its alias `=~`.

For example:

    describe "some component" [
      it "has some behaviour" begin
        expect my_component (has some_behaviour)
      end;
      describe "in some particular context" [
        it "has some different behaviour" begin
          expect my_component (has different_behaviour)
        end;
        it "does something else too" begin
          my_component =~ (does something_else)
        end
      ]
    ]

A [working example](https://github.com/rapha/Ospecl/blob/master/examples/account_spec.ml) can be found in the examples directory, and another one [here](https://gist.github.com/896752#file_spec.ml).

Ospecl comes with a core set of matchers in `Ospecl.Matchers`, but you can define your own on top of `Ospecl.Matcher` that better describe your domain.

Ospecl also comes with a simple runner function (`Ospecl.Run.console`) designed to be executed in a script run from the command line, but again you can build custom runners by using `Ospecl.Spec.Exec.execute` with your own set of handlers for the execution events.
