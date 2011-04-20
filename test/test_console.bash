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
  Ospecl.Console.progress ~matching:(Str.regexp "") ~color:false [
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
    it "passes" (1 =~ is equal_to_int 1);
    it "fails" (1 =~ is (less_than 0));
    it "skips" (pending "implementation");
  ]
  '
assert_stdout "$spec" "^\.F\*$"
assert_stdout "$spec" "^Finished in [0-9]\+\.[0-9]\+ seconds$"
assert_stdout "$spec" "^3 examples, 1 failure, 1 pending$"
assert_stdout "$spec" "^Pending:$"
assert_stdout "$spec" "^  something skips$"
assert_stdout "$spec" "^    implementation$"
assert_stdout "$spec" "^Failures:$"
assert_stdout "$spec" "^  1) something fails$"
assert_stdout "$spec" "^        Spec.Expectation_failed(\"Expected less than 0 but got 1\")$"

assert_exit_code "$spec" 1
