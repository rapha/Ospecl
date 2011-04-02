open Ospecl.Spec
open Ospecl.Matchers

let test_eval =
  let spec =
    (* dummy component just for demonstration *)
    let make_bulb on = on in
    let toggle bulb = not bulb in
    let is_off bulb = not bulb in
    let is_on bulb = bulb in

    describe "a light bulb" [
      describe "that is on" [
        let bulb = make_bulb true in
        describe "when toggled" begin
          let bulb = toggle bulb in [
            it "is off" (is_off bulb =~ is true');
            it "is not on" (is_on bulb =~ is (not' true'));
          ]
        end
      ]
    ]
  in
  let expected_results = [
    Passed "a light bulb that is on when toggled is off";
    Passed "a light bulb that is on when toggled is not on";
  ]
  in
  assert (eval spec = expected_results)

let test_exec =
  let specs = [
    describe "1" [
      describe "+" [
        it "1 = 2" (1 + 1 =~ is (equal_to_int 2));
        it "2 = 3" (1 + 2 =~ is (equal_to_int 3));
      ];
      describe "-" [
        it "1 = 0" (1 - 1 =~ is (equal_to_int 0));
        it "2 = -1" (1 - 2 =~ is (equal_to_int (-1)));
      ];
    ]
  ]
  in
  let expected_events = 
    let open Exec in 
    [
      Execution_started;
      Group_started "1";
        Group_started "1 +";
          Example_started "1 + 1 = 2";
          Example_finished (Passed "1 + 1 = 2");
          Example_started "1 + 2 = 3";
          Example_finished (Passed "1 + 2 = 3");
        Group_finished "1 +";
        Group_started "1 -";
          Example_started "1 - 1 = 0";
          Example_finished (Passed "1 - 1 = 0");
          Example_started "1 - 2 = -1";
          Example_finished (Passed "1 - 2 = -1");
        Group_finished "1 -";
      Group_finished "1";
      Execution_finished;
    ]
  in
  let log_to record event = record := !record @ [event] in
  let record1, record2 = ref [], ref [] in

  Exec.execute [log_to record1; log_to record2] specs;

  assert (!record1 = expected_events);
  assert (!record2 = expected_events)
