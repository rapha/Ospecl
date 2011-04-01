open Printf
open Ospecl.Spec
open Ospecl.Spec.Exec
open Ospecl.Run
open Ospecl.Matchers

let assert_emits values handler events =
  let emitted = ref [] in
  let handle = handler (fun x -> emitted := !emitted @ [x]) in
  List.iter handle events;
  assert (!emitted = values)

let pass = Pass ""
let fail = Fail ("", Not_found)

let test_summary =
  assert_emits [(0, 0, 0)] Handlers.summary [
    Execution_finished
  ];
  assert_emits [(1, 0, 0)] Handlers.summary [
    Example_finished pass;
    Execution_finished
  ];
  assert_emits [(0, 1, 0)] Handlers.summary [
    Example_finished fail;
    Execution_finished
  ];
  assert_emits [(2, 1, 0)] Handlers.summary [
    Example_finished pass;
    Example_finished pass;
    Example_finished fail;
    Execution_finished
  ]

let test_exit_code =
  assert_emits [0] Handlers.exit_code [
    Execution_finished
  ];
  assert_emits [0] Handlers.exit_code [
    Example_finished pass;
    Execution_finished
  ];
  assert_emits [1] Handlers.exit_code [
    Example_finished fail;
    Execution_finished
  ];
  assert_emits [1] Handlers.exit_code [
    Example_finished pass;
    Example_finished pass;
    Example_finished fail;
    Example_finished fail;
    Execution_finished
  ]

let test_total_time =
  let emitted = ref None in
  let handler = Handlers.total_time (fun duration -> emitted := Some duration) in

  handler Execution_started;
  handler Execution_finished;

  match !emitted with
  | None -> assert false
  | Some duration -> assert (duration >= 0.)

let test_each_result =
  assert_emits [pass; fail]
    Handlers.each_result [
      Example_finished pass;
      Example_finished fail;
    ]

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
    Pass "a light bulb that is on when toggled is off";
    Pass "a light bulb that is on when toggled is not on";
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
  let expected_events = [
    Execution_started;
    Group_started "1";
      Group_started "1 +";
        Example_started "1 + 1 = 2";
        Example_finished (Pass "1 + 1 = 2");
        Example_started "1 + 2 = 3";
        Example_finished (Pass "1 + 2 = 3");
      Group_finished "1 +";
      Group_started "1 -";
        Example_started "1 - 1 = 0";
        Example_finished (Pass "1 - 1 = 0");
        Example_started "1 - 2 = -1";
        Example_finished (Pass "1 - 2 = -1");
      Group_finished "1 -";
    Group_finished "1";
    Execution_finished;
  ]
  in
  let log_to record event = record := !record @ [event] in
  let record1, record2 = ref [], ref [] in

  execute [log_to record1; log_to record2] specs;

  assert (!record1 = expected_events);
  assert (!record2 = expected_events)