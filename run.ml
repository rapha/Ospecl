open Specify

let progress event =
  let char_of_outcome = function
    | Pass -> '.'
    | Fail _ -> 'F'
    | Error _ -> 'E'
  in
  match event with
  | Execution_started | Execution_finished
  | Group_started _ | Group_finished _
  | Example_started _ ->
      ()
  | Example_finished (Result (_, outcome)) ->
      print_char (char_of_outcome outcome)

let console specs =
  let start_time = Unix.gettimeofday () in
  let results = eval specs in
  let finish_time = Unix.gettimeofday () in
  let duration = finish_time -. start_time in
  let (output, passed, failed, errored) = List.fold_left (fun (out, p, f, e) result ->
    match result with
    | Result (_, Pass) ->
        (out, p+1, f, e)
    | Result (desc, Fail problem) ->
        let fail_line = Printf.sprintf "FAIL: '%s' because '%s'\n" desc problem in
        (out ^ fail_line, p, f+1, e)
    | Result (desc, Error ex) ->
        let error_line = Printf.sprintf "ERROR: '%s' because %s\n" desc (Printexc.to_string ex) in
        (out ^ error_line, p, f, e+1)
  ) ("", 0, 0, 0) results in

  let examples = passed + failed + errored in
  let failures = failed + errored in

  let exit_code = 0 +
    (if failed > 0 then 1 else 0) +
    (if errored > 0 then 2 else 0)
  in

  Printf.printf "%s\nFinished in %f seconds\n%d example(s), %d failure(s).\n" output duration examples failures;
  exit exit_code
