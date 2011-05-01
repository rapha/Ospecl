## Overview

Ospecl is a library for writing executable specifications for your OCaml code à la [rspec](http://rspec.info/).

Ospecl allows you to build *specs*, which are nested data structures combining textual descriptions of the component's behaviour, together with the code that can verify it. Specs may then be executed to verify your component's continued conformance.

Specs are built using calls to `describe` to provide context for a group of executable examples, each constructed through `it` calls. Examples contain a single *expectation* which uses *matchers* to test whether a given value meets some criteria.


## Usage

    let component_spec = 
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

Here, `describe` takes a string, which, well, describes what you're specifying, and a list of child specs. `it` takes a string, which describes the behaviour that this example verifies, and an expectation. `expect` takes a value and a matcher for that value and returns an expectation, which will be checked when the spec is executed. `=~` is an alias for `expect` which can be used infix.

As you can see, specs may be nested arbitrarily within each other, so you can organise your contexts and examples as you see fit.

A [working example](https://github.com/rapha/Ospecl/blob/master/examples/account_spec.ml) can be found in the examples directory, and another one [here](https://gist.github.com/896752#file_spec.ml).


## Installation

    $ make install

will install `ospecl` as a findlib package.

    $ make uninstall

will uninstall it.


## Matchers

Matchers are used to construct expectations. They are based on the idea of matchers in [hamcrest](http://code.google.com/p/hamcrest/), which is like a predicate coupled with a way of describing successful and unsucessful matches. Matchers are nice because they are both descriptive on their own, and may be composed to build arbitrary new self-describing constraints on values. Ospecl comes with a core set of matchers in `Ospecl.Matchers`, but you can define additional matchers on top of `Ospecl.Matcher` to fit your domain.

## Execution

There are several ways to execute specs.

### Command line

#### Sequentially

First:

    $ ln -s `pwd`/ospecl ~/bin/ospecl

Thereafter:

    $ ospecl -color -I dir_with_cmo_files my_spec1.ml my_spec2.ml my_spec3.ml 
    
`ospecl` accepts a list of ocaml script files, each of which must define a single value called `specs` of type `Ospecl.Spec.t list`. The specs from each of these files will be executed and the results reported together.

#### Parallel

You can start any number of `ospecl_server` s and have `ospecl_client` s connect to them with any number of parallel connections. An ospecl server will respond to each connection by forking off a new process which receives spec file names, executes the specs defined in them, and sends the execution events back to the client. You may thus request a client to open several connections to the same server, or connect it to several different servers and the client will distribute the specs across these connections.

The servers need not be on the same machine as the client but currently no provision is made for sending the spec files themselves or the modules they reference from the client to the server, so at present they must share a filesystem in order for the server to be able to discover the spec files. The servers can be started with a list of directories to search for the referenced modules.

e.g.

    $ ospecl_server -I <dir_with_cmo_files> -port 7000 &
    $ ospecl_client -address 127.0.0.1:7000 -j 4 spec/*.ml

or if the client is started in a different directory from the server

    $ find `pwd`/spec/*.ml | xargs ospecl_client -address 127.0.0.1:7000 -j 4

### Runner function

Specs may be executed from your own code by calling the `Ospecl.Spec.Exec.execute` function, which takes a list of `handler` s and a list of specs and executes each spec, passing the appropriate execution events to the handlers as they occur. Two sets of handlers are currently provided: `Ospecl.Console.progress` and `Ospecl.Console.documentation`. The meaning of these handlers roughly corresponds to the 'progress' and 'documentation' formats in rspec.

You may also define your own handlers to handle execution events in whatever way you wish. The execution events are defined in the `Ospecl.Spec.Exec` module.
