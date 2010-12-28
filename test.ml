open Ospecl

let _ = 
  assert (run (it "passes" (fun () -> ())) = [Pass "passes"]);
  assert (run (it "fails" (expect 1 ((=) 0))) = [Fail "fails"]);
  assert (run (it "errors" (fun () -> failwith "no")) = [Error ("errors", Failure "no")]);
  assert (run (describe "nothing" []) = []);
  assert (run (
    describe "thing that" [
      it "should be" (fun () -> ());
      it "should not be" (expect "a" ((=) "b"));
    ]
  ) = [Pass "thing that should be"; Fail "thing that should not be"]);
  assert (run (
        let make_bulb on = on in
        let toggle b = not b in
        let is_off b = not b in

        describe "a light bulb" [
          describe "that is on" [
            describe "when toggled" [
              it "is off" (fun () ->
                let bulb = make_bulb true in
                let toggled = toggle bulb in
                expect (is_off toggled) ((=) true) ()
              );
            ]
          ]
        ]
  ) = [Pass "a light bulb that is on when toggled is off"]);
