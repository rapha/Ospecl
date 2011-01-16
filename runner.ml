#load "ospecl.cma";;
#load "bulb_spec.cma";;
#load "switch_spec.cma";;

let console_listener = 
  let listener depth passes failures errors event =
    if depth = 0 then 
      let succeeded = (failures = 0 && errors = 0) in
      Printf.printf "BUILED %s. Pass: %d, Fail: %d, Error: %d" succeeded passes failures errors
    else 
      match event with
      | Describe_started desc -> listener (depth+1) passes failures errors 
      | Describe_ended desc -> listener (depth-1) passes failures errors
      | It_started desc -> listener (depth+1) passes failures errors
      | It_passed desc -> listener (depth-1) (passes+1) failures errors
      | It_failed desc -> listener (depth-1) passes (failures+1) errors
      | It_errored (desc, ex) -> listener (depth-1) passes failures (errors+1)
  in listener 0 0 0 0

Ospecl.run [Bulb_spec.spec ; Switch_spec.spec] ~listeners:[console_listener]

let specs = 
  describe "a light bulb" [
    describe "that is on" [
      it "should be on" (fun () ->
        asdfasdf
      );
      it "should be awesome" (check bulb is_awesome)
    ]
  ]

let (|>) x f = f x

open Ospecl

let string_of_result = function
  | Pass description -> "PASS: " ^ description
  | Fail description -> "FAIL: " ^ description
  | Error (description,e) -> "ERROR: " ^ description

let exec specs run_listeners =
  let results = run (it "hi" (fun () -> ())) in
  let errors = List.filter (function Error (str, e) -> true | _ -> false) results in
  let failures = List.filter (function Fail str -> true | _ -> false) results in
  failures |> List.map string_of_result |> List.iter print_endline;
  errors |> List.map string_of_result |> List.iter print_endline;
  exit (List.length errors + List.length failures)

  ()

let _ =
  print_endline "done"
