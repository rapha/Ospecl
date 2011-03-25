open Printf
open Ospecl.Specify
open Ospecl.Run
open Ospecl.Matchers

let assert_emits values handler events =
  let emitted = ref [] in
  let handle = handler (fun x -> emitted := !emitted @ [x]) in
  List.iter handle events;
  assert (!emitted = values)

let test_progress =
  assert_emits ['.'; 'F'; 'E'; '\n']
    Handle.progress [
      Example_finished (Result ("", Pass));
      Example_finished (Result ("", Fail "bad"));
      Example_finished (Result ("", Error Not_found));
      Execution_finished;
    ];

  assert_emits []
    Handle.progress [
      Execution_started;
      Group_started "g";
      Group_finished "g";
      Example_started "e"
  ]

let test_summary =
  assert_emits [(0, 0, 0)] Handle.summary [
    Execution_finished
  ];
  assert_emits [(1, 0, 0)] Handle.summary [
    Example_finished (Result ("", Pass));
    Execution_finished
  ];
  assert_emits [(0, 1, 0)] Handle.summary [
    Example_finished (Result ("", Fail "bad"));
    Execution_finished
  ];
  assert_emits [(0, 0, 1)] Handle.summary [
    Example_finished (Result ("", Error Not_found));
    Execution_finished
  ];
  assert_emits [(2, 1, 0)] Handle.summary [
    Example_finished (Result ("", Pass));
    Example_finished (Result ("", Pass));
    Example_finished (Result ("", Fail "bad"));
    Execution_finished
  ]

let test_exit_code =
  assert_emits [0] Handle.exit_code [
    Execution_finished
  ];
  assert_emits [0] Handle.exit_code [
    Example_finished (Result ("", Pass));
    Execution_finished
  ];
  assert_emits [1] Handle.exit_code [
    Example_finished (Result ("", Fail "bad"));
    Execution_finished
  ];
  assert_emits [2] Handle.exit_code [
    Example_finished (Result ("", Error Not_found));
    Execution_finished
  ];
  assert_emits [3] Handle.exit_code [
    Example_finished (Result ("", Pass));
    Example_finished (Result ("", Pass));
    Example_finished (Result ("", Fail "bad"));
    Example_finished (Result ("", Fail "bad"));
    Example_finished (Result ("", Error Not_found));
    Example_finished (Result ("", Error Not_found));
    Execution_finished
  ]

let test_total_time =
  let emitted = ref None in
  let handler = Handle.total_time (fun duration -> emitted := Some duration) in

  handler Execution_started;
  handler Execution_finished;

  match !emitted with
  | None -> assert false
  | Some duration -> assert (duration >= 0.)

let test_each_result =
  assert_emits
    [Result ("", Pass); Result("", Fail "bad"); Result ("", Error Not_found)]
    Handle.each_result [
      Example_finished (Result ("", Pass));
      Example_finished (Result ("", Fail "bad"));
      Example_finished (Result ("", Error Not_found));
    ]

let test_eval =
  let specs =
    (* dummy component just for demonstration *)
    let make_bulb on = on in
    let toggle bulb = not bulb in
    let is_off bulb = not bulb in
    let is_on bulb = bulb in
    [
      describe "a light bulb" [
        describe "that is on" [
          let bulb = make_bulb true in
          describe "when toggled" begin
            let bulb = toggle bulb in [
              it "is off" (fun _ -> expect (is_off bulb) (equal_to_bool true));
              it "is not on" (fun _ -> expect (is_on bulb) (not' (equal_to_bool true)));
            ]
          end
        ]
      ]
    ]
  in
  let expected_results = [
    Result ("a light bulb that is on when toggled is off", Pass);
    Result ("a light bulb that is on when toggled is not on", Pass)
  ]
  in
  assert (eval specs = expected_results)

let test_exec =
  let specs = [
    describe "1" [
      describe "+" [
        it "1 = 2" (fun _ -> expect (1+1) (equal_to_int 2));
        it "2 = 3" (fun _ -> expect (1+2) (equal_to_int 3));
      ];
      describe "-" [
        it "1 = 0" (fun _ -> expect (1-1) (equal_to_int 0));
        it "2 = -1" (fun _ -> expect (1-2) (equal_to_int (-1)));
      ];
    ]
  ]
  in
  let expected_events = [
    Execution_started;
    Group_started "1";
      Group_started "1 +";
        Example_started "1 + 1 = 2";
        Example_finished (Result ("1 + 1 = 2", Pass));
        Example_started "1 + 2 = 3";
        Example_finished (Result ("1 + 2 = 3", Pass));
      Group_finished "1 +";
      Group_started "1 -";
        Example_started "1 - 1 = 0";
        Example_finished (Result ("1 - 1 = 0", Pass));
        Example_started "1 - 2 = -1";
        Example_finished (Result("1 - 2 = -1",Pass));
      Group_finished "1 -";
    Group_finished "1";
    Execution_finished;
  ]
  in
  let log_to record event = record := !record @ [event] in
  let record1, record2 = ref [], ref [] in

  exec [log_to record1; log_to record2] specs;

  assert (!record1 = expected_events);
  assert (!record2 = expected_events)
