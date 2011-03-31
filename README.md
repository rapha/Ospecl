Ospecl is a simple testing library for OCaml. You can write BDD specifications for your components à la rspec, and execute them.

A spec is built up using calls to `describe` to provide context and `it` for executable examples. Expectations can be described by `expect`-ing a value to match a provided matcher. `expect` can also be used via its alias `=~`.

For example:

    describe "some component" [
      it "has some behaviour" (fun _ ->
        expect my_component (has some_behaviour)
      )
      describe "in some particular context" [
        it "has some different behaviour" (fun _ ->
          expect my_component (has different_behaviour)
        );
        it "does something else too" (fun _ ->
          my_component =~ (does something_else)
        )
      ]
    ]

A [working example](https://github.com/rapha/Ospecl/examples/account_spec.ml) can be found in the examples directory.

Ospecl comes with a basic set of matchers in `Ospecl.Matchers`, but you can define your own on top of `Ospecl.Matcher` that better describe your domain.

Ospecl also comes with a basic runner function (`Ospecl.Run.console`) designed to be executed in a script run from the command line, but again you can build custom runners by using `Ospecl.Spec.Exec.execute` with your own set of handlers for the execution events.
