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
#load "unix.cma"
#load "ospecl.cma"

open Ospecl.Specify
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
  expected_exit=$3

  out=$(execute_spec "$spec_src")
  actual_exit=$?

  assert_matches "Exit code for '$spec_src'" $actual_exit $expected_exit
}

spec='
  describe "something" [
    it "passes" (fun () -> ());
    it "fails" (fun _ -> expect 1 (less_than 0));
    it "errors" (fun () -> failwith "no")
  ]
  '

assert_stdout "$spec" "^.FE$"
assert_stdout "$spec" "^Finished in [0-9]\+\.[0-9]\+ seconds$"
assert_stdout "$spec" "^3 example(s), 1 failure(s), 1 error(s)$"

assert_exit_code "$spec" 3
