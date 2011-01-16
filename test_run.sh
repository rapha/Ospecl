function assert_equal {
  desc=$1
  expected=$2
  actual=$3

  if [ "$expected" != "$actual" ]; then 
    echo -n "$desc wrong. "
    echo "Expected \"$expected\" but was \"$actual\""
    exit 1
  fi
}

function assert_stdout_and_exit_code {
  spec_code=$1
  expected_out=$2
  expected_exit=$3

  actual_out=$(ocaml <(cat <<EOF
#load "ospecl.cma"
#load "matchers.cma"
#load "run.cma"

open Ospecl
open Matchers
open Run

let _ =
  console begin
    $spec_code
  end
EOF
  ))
  actual_exit=$?

  assert_equal "Exit code" $expected_exit $actual_exit
  assert_equal "Standard output" "$expected_out" "$actual_out"
}


assert_stdout_and_exit_code 'it "passes" (fun () -> ())' \
  "Build successful. Passed: 1, Failed: 0, Errored: 0." 0

assert_stdout_and_exit_code 'it "fails" (expect 1 (less_than 0))' \
  "Build failed. Passed: 0, Failed: 1, Errored: 0." 1

assert_stdout_and_exit_code 'it "fails" (fun () -> failwith "fail")' \
  "Build failed. Passed: 0, Failed: 0, Errored: 1." 2

assert_stdout_and_exit_code '
  describe "anything" [
    it "passes" (fun () -> ());
    it "passes again" (fun () -> ())
  ]
  ' \
  "Build successful. Passed: 2, Failed: 0, Errored: 0." 0

assert_stdout_and_exit_code '
  describe "anything" [
    it "passes" (fun () -> ());
    it "fails" (expect 1 (less_than 0));
    it "errors" (fun () -> failwith "no")
  ]
  ' \
  "Build failed. Passed: 1, Failed: 1, Errored: 1." 3
