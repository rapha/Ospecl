function assert_matches {
  description=$1
  actual=$2
  pattern=$3

  if [[ -z $(echo "$actual" | grep "$pattern") ]]; then
    echo -n "$description was wrong. "
    echo "Expected matches \"$pattern\" but was \"$actual\""
    exit 1
  fi
}

function execute_spec {
  spec_src=$1

  ocaml <(cat <<EOF
#load "str.cma"
#load "unix.cma"
#load "ospecl.cma"

open Ospecl.Spec
open Ospecl.Matchers

let _ =
  Ospecl.Run.console [
    $spec_src
  ]
EOF
  )
}

function assert_stdout {
  spec_src=$1
  expected_out=$2

  actual_out=$(execute_spec "$spec_src")
  assert_matches "Standard output for '$spec_src'" "$actual_out" "$expected_out"
}

function assert_exit_code {
  spec_src=$1
  expected_exit=$2

  out=$(execute_spec "$spec_src")
  actual_exit=$?

  assert_matches "Exit code for '$spec_src'" $actual_exit $expected_exit
}

spec='
  describe "something" [
    it "passes" (fun () -> ());
    it "fails" (fun _ -> 1 =~ is (less_than 0));
  ]
  '

assert_stdout "$spec" "^.F$"
assert_stdout "$spec" "^Finished in [0-9]\+\.[0-9]\+ seconds$"
assert_stdout "$spec" "^2 examples, 1 failure$"

assert_exit_code "$spec" 1
