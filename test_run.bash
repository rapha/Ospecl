function assert_matches {
  description=$1
  actual=$2
  pattern=$3

  if [[ -z $(echo "$actual" | grep "$pattern") ]]; then
    echo -n "$description wrong. "
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

function assert_stdout_and_exit_code {
  spec_src=$1
  expected_out=$2
  expected_exit=$3

  actual_out=$(execute_spec "$spec_src")
  actual_exit=$?

  assert_matches "Exit code for $spec_src" $actual_exit $expected_exit 
  assert_matches "Standard output for $spec_src" "$actual_out" "$expected_out"
}

assert_stdout_and_exit_code 'it "passes" (fun _ -> ())' \
  "1 example(s), 0 failure(s)." \
  0

assert_matches "logging output" $(execute_spec 'it "passes" (fun _ -> ())') "."

assert_stdout_and_exit_code 'it "fails" (fun _ -> expect 1 (less_than 0))' \
  "1 example(s), 1 failure(s)." \
  1

assert_stdout_and_exit_code 'it "errors" (fun () -> failwith "err")' \
  "1 example(s), 1 failure(s)." \
  2

assert_stdout_and_exit_code '
  it "passes something" (fun () -> ());
  it "passes something else" (fun () -> ())
  ' \
  "2 example(s), 0 failure(s)." \
  0

assert_stdout_and_exit_code '
  describe "something" [
    it "passes" (fun () -> ());
    it "fails" (fun _ -> expect 1 (less_than 0));
    it "errors" (fun () -> failwith "no")
  ]
  ' \
  "3 example(s), 2 failure(s)." \
  3
