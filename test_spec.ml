open Printf
open Ospecl.Spec
open Ospecl.Matchers

let test_eval_it () =
  assert (eval [] = []);
  assert (
    eval [it "is a nop" (fun () -> ())]
    = 
    [Result ("is a nop", Pass)]
  );
  assert (
    eval [it "has a wrong expectation" (fun _ -> expect (equal_to_int 0) 1)]
    = 
    [Result ("has a wrong expectation", Fail "Expected 0 but was 1")]
  );
  assert (
    eval [it "errors" (fun () -> failwith "no")]
    = 
    [Result ("errors",Error (Failure "no"))]
  )

let test_eval_describe () = 
  assert (
    eval [describe "nothing" []]
    = 
    []
  );
  assert (
    eval [
      describe "thing that" [
        it "should be" (fun () -> ());
        it "should not be" (fun _ -> expect (equal_to_string "up") "down");
      ]
    ] 
    = 
    [
      Result ("thing that should be", Pass); 
      Result ("thing that should not be", Fail "Expected up but was down")
    ]
  );
  assert (
    (* dummy component just for demonstration *)
    let make_bulb on = on in
    let toggle bulb = not bulb in
    let is_off bulb = not bulb in
    let is_on bulb = bulb in

    eval [
      describe "a light bulb" [
        describe "that is on" [
          let bulb = make_bulb true in
          describe "when toggled" begin
            let bulb = toggle bulb in [
              it "is off" (fun _ -> expect (equal_to_bool true) (is_off bulb));
              it "is not on" (fun _ -> expect (not' (equal_to_bool true)) (is_on bulb));
            ] 
          end
        ]
      ]
    ]
    = 
    [
      Result ("a light bulb that is on when toggled is off", Pass);
      Result ("a light bulb that is on when toggled is not on", Pass)
    ]
  )

let test_exec () =
  let logging_listener log event = log := !log @ [event] in

  let event_log = ref [] in
  exec [logging_listener event_log] [];
  assert (!event_log = []);

  (* exec passes (It_started desc) and (It_finished result) events to the listener *)

    (* for passing spec *)
    let event_log = ref [] in
    exec [logging_listener event_log] [it "passes" (fun () -> ())];
    assert (!event_log = [
      It_started "passes"; 
      It_finished (Result ("passes", Pass))
    ]);

    (* for failing spec *)
    let event_log = ref [] in
    exec [logging_listener event_log] [it "fails" (fun _ -> expect (equal_to_int 0) 1)];
    assert (!event_log = [
      It_started "fails"; 
      It_finished (Result ("fails", Fail "Expected 0 but was 1"))
    ]);

    (* for erroring spec *)
    let event_log = ref [] in
    exec [logging_listener event_log] [it "errors" (fun () -> failwith "no")];
    assert (!event_log = [
      It_started "errors"; 
      It_finished (Result ("errors", Error (Failure "no")))
    ]);

  (* exec passes Describe_started, then events from nested specs, then Describe_finished, events to the listener *) 

    (* for nested "it" specs *)
    let event_log = ref [] in
    exec [logging_listener event_log] [
      describe "1" [
        it "- 1 = 0" (fun _ -> expect (equal_to_int 0) (1-1));
        it "+ 1 = 0" (fun _ -> expect (equal_to_int 0) (1+1));
        it "/ 0 = 1" (fun _ -> expect (equal_to_int 0) (1/0));
      ]
    ];
    assert (!event_log = [
      Describe_started "1"; 
        It_started "1 - 1 = 0"; 
        It_finished (Result ("1 - 1 = 0", Pass)); 
        It_started "1 + 1 = 0"; 
        It_finished (Result ("1 + 1 = 0", Fail "Expected 0 but was 2")); 
        It_started "1 / 0 = 1"; 
        It_finished (Result ("1 / 0 = 1", Error Division_by_zero)); 
      Describe_finished "1"
    ]);

    (* for nested "describe" specs *)
    let event_log = ref [] in
    exec [logging_listener event_log] [
      describe "1" [
        describe "+" [
          it "1 = 2" (fun _ -> expect (equal_to_int 2) (1+1));
          it "2 = 3" (fun _ -> expect (equal_to_int 3) (1+2));
        ];
        describe "-" [
          it "1 = 0" (fun _ -> expect (equal_to_int 0) (1-1));
          it "2 = -1" (fun _ -> expect (equal_to_int (-1)) (1-2));
        ];
      ]
    ];
    assert (!event_log = [
      Describe_started "1"; 
        Describe_started "1 +";
          It_started "1 + 1 = 2"; 
          It_finished (Result ("1 + 1 = 2", Pass));
          It_started "1 + 2 = 3"; 
          It_finished (Result ("1 + 2 = 3", Pass));
        Describe_finished "1 +";
        Describe_started "1 -";
          It_started "1 - 1 = 0"; 
          It_finished (Result ("1 - 1 = 0", Pass));
          It_started "1 - 2 = -1"; 
          It_finished (Result("1 - 2 = -1",Pass));
        Describe_finished "1 -";
      Describe_finished "1";
    ])

let _ = 
  test_eval_it ();
  test_eval_describe ();
  test_exec ()
