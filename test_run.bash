function assert_equal {
  description=$1
  expected=$2
  actual=$3

  if [ "$expected" != "$actual" ]; then 
    echo -n "$description wrong. "
    echo "Expected \"$expected\" but was \"$actual\""
    exit 1
  fi
}

function assert_stdout_and_exit_code_for_spec {
  spec_src=$1
  expected_out=$2
  expected_exit=$3

  actual_out=$(ocaml <(cat <<EOF
#load "ospecl.cma"
#load "matchers.cma"
#load "run.cma"

open Ospecl
open Matchers

let _ =
  Run.console [
    $spec_src
  ]
EOF
  ))
  actual_exit=$?

  assert_equal "Exit code" $expected_exit $actual_exit
  assert_equal "Standard output" "$expected_out" "$actual_out"
}


assert_stdout_and_exit_code_for_spec 'it "passes" (fun () -> ())' \
  "Build successful. Passed: 1, Failed: 0, Errored: 0." 0

assert_stdout_and_exit_code_for_spec 'it "fails" (expect 1 (less_than 0))' \
  "Build failed. Passed: 0, Failed: 1, Errored: 0." 1

assert_stdout_and_exit_code_for_spec 'it "fails" (fun () -> failwith "fail")' \
  "Build failed. Passed: 0, Failed: 0, Errored: 1." 2

assert_stdout_and_exit_code_for_spec '
  it "passes something" (fun () -> ());
  it "passes something else" (fun () -> ())
  ' \
  "Build successful. Passed: 2, Failed: 0, Errored: 0." 0

assert_stdout_and_exit_code_for_spec '
  describe "anything" [
    it "passes" (fun () -> ());
    it "fails" (expect 1 (less_than 0));
    it "errors" (fun () -> failwith "no")
  ]
  ' \
  "Build failed. Passed: 1, Failed: 1, Errored: 1." 3
