open Printf
open Ospecl
open Matchers

(* useful for debugging *)
let (|>) x f = f x
let (|-) f g x = g (f x)
let (-|) f g x = f (g x)

let string_of_result = function
  | Result (desc, Pass) -> sprintf "Result (\"%s\", Pass)" desc
  | Result (desc, Fail failure) -> sprintf "Result (\"%s\", Fail %s\")" desc failure
  | Result (desc, Error e) -> sprintf "Result (\"%s\", Error e)" desc

let string_of_event = function
  | It_started desc -> "It_started (\"" ^ desc ^ "\")"
  | It_finished result -> "It_finished (" ^ (string_of_result result) ^ ")"
  | Describe_started desc -> "Describe_started (\"" ^ desc ^ "\")"
  | Describe_finished desc -> "Describe_finished (\"" ^ desc ^ "\")"

let print_events events =
    events |> List.map string_of_event |> List.iter print_endline

(* main *)
let _ = 
  assert (eval (it "is a nop" (fun () -> ())) = [Result ("is a nop", Pass)]);
  assert (eval (it "has a wrong expectation" (expect 1 (equal_to_int 0))) = [Result ("has a wrong expectation", Fail "Expected 0 but was 1")]);
  assert (eval (it "errors" (fun () -> failwith "no")) = [Result ("errors",Error (Failure "no"))]);
  assert (eval (describe "nothing" []) = []);
  assert (eval (
    describe "thing that" [
      it "should be" (fun () -> ());
      it "should not be" (expect 'a' (equal_to_char 'b'));
    ]
  ) = [Result ("thing that should be", Pass); Result ("thing that should not be", Fail "Expected b but was a")]);
  assert (eval (
        let make_bulb on = on in
        let toggle b = not b in
        let is_off b = not b in

        describe "a light bulb" [
          describe "that is on" [
            describe "when toggled" [
              it "is off" (fun () ->
                let bulb = make_bulb true in
                let toggled = toggle bulb in
                expect (is_off toggled) (equal_to_bool true) ()
              );
            ]
          ]
        ]
  ) = [Result ("a light bulb that is on when toggled is off", Pass)]);

  let record_into acc event = acc := !acc @ [event] in

  (* exec passes (It_started desc) and (It_finished result) events to the listener *)

     (* for passing spec *)
     let events = ref [] in
     exec [record_into events] (it "passes" (fun () -> ()));
     assert (!events = [It_started "passes"; It_finished (Result ("passes", Pass))]);

     (* for failing spec *)
     let events1 = ref [] in
     exec [record_into events1] (it "fails" (expect 1 (equal_to_int 0)));
     assert (!events1 = [It_started "fails"; It_finished (Result ("fails", Fail "Expected 0 but was 1"))]);

     (* for erroring spec *)
     let events = ref [] in
     exec [record_into events] (it "errors" (fun () -> failwith "no"));
     assert (!events = [It_started "errors"; It_finished (Result ("errors", Error (Failure "no")))]);

  (* exec passes Describe_started, then events from nested specs, then Describe_finished, events to the listener *) 
  

    (* for nested "it" specs *)
    let events = ref [] in
    exec [record_into events] begin
      describe "1" [
        it "- 1 = 0" (expect (1-1) (equal_to_int 0));
        it "+ 1 = 0" (expect (1+1) (equal_to_int 0));
        it "/ 0 = 1" (fun () -> expect (1/0) (equal_to_int 0) ());
(*
        describe "[1;2;3]" [
          it "has length 3" (expect [1;2;3] (has_length 3));
          it "has odd numbers" (expect [1;2;3] (not' (every_item even)));
          it "has odd numbers" (expect [1;2;3] (has_item odd));
        ]
*)
      ]
    end;
    print_events !events;
    assert (!events = [
      Describe_started "1"; 
        It_started "1 - 1 = 0"; It_finished (Result ("1 - 1 = 0", Pass)); 
        It_started "1 + 1 = 0"; It_finished (Result ("1 + 1 = 0", Fail "Expected 0 but was 2")); 
        It_started "1 / 0 = 1"; It_finished (Result ("1 / 0 = 1", Error Division_by_zero)); 
      Describe_finished "1"];
    );

    (* for nested "describe" specs *)
    let events = ref [] in
    exec [record_into events] begin
      describe "1" [
        describe "+" [
          it "1 = 2" (expect (1+1) (equal_to_int 2));
          it "2 = 3" (expect (1+2) (equal_to_int 3));
        ];
        describe "-" [
          it "1 = 0" (expect (1-1) (equal_to_int 0));
          it "2 = -1" (expect (1-2) (equal_to_int (-1)));
        ];
      ]
    end;
    assert (!events = [
      Describe_started "1"; 
        Describe_started "1 +";
          It_started "1 + 1 = 2"; It_finished (Result ("1 + 1 = 2", Pass));
          It_started "1 + 2 = 3"; It_finished (Result ("1 + 2 = 3", Pass));
        Describe_finished "1 +";
        Describe_started "1 -";
          It_started "1 - 1 = 0"; It_finished (Result ("1 - 1 = 0", Pass));
          It_started "1 - 2 = -1"; It_finished (Result("1 - 2 = -1",Pass));
        Describe_finished "1 -";
      Describe_finished "1";
    ]);

