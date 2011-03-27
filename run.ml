open Specify

type execution_event =
  | Execution_started
  | Execution_finished
  | Group_started of string
  | Group_finished of string
  | Example_started of string
  | Example_finished of result

module Handle = struct
  type handler = execution_event -> unit

  let char_of_outcome = function
    | Pass -> '.'
    | Fail _ -> 'F'
    | Error _ -> 'E'

  let progress callback = function
    | Example_finished (Result (_, outcome)) ->
        callback (char_of_outcome outcome)
    | Execution_finished ->
        callback '\n'
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let total_time callback =
    let start = ref None in
    function
    | Execution_started ->
        start := Some (Unix.gettimeofday ())
    | Execution_finished ->
        let finish_time = Unix.gettimeofday () in
        begin match !start with
        | None -> failwith "We don't have a start time yet."
        | Some start_time ->
            let duration = finish_time -. start_time in
            callback (duration)
        end
    | Group_started _ | Group_finished _ | Example_started _ | Example_finished _ ->
        ()

  let summary callback =
    let passes = ref 0 in
    let failures = ref 0 in
    let errors = ref 0 in
    function
    | Example_finished (Result (_, outcome)) -> begin
        match outcome with
        | Pass -> incr passes
        | Fail _ -> incr failures
        | Error _ -> incr errors
      end
    | Execution_finished ->
        callback (!passes, !failures, !errors)
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let failure_report callback =
    let failures = ref [] in
    function
    | Example_finished (Result (_, outcome) as r) -> begin
        match outcome with
        | Pass -> ()
        | Fail _ | Error _ -> failures := r :: !failures
      end
    | Execution_finished ->
        callback (List.rev !failures)
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let exit_code callback =
    let code = ref 0 in
    function
    | Example_finished (Result (_, outcome)) -> begin
        match outcome with
        | Pass -> ()
        | Fail _ -> code := !code lor 0b01
        | Error _ -> code := !code lor 0b10
      end
    | Execution_finished ->
        callback !code
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let each_result callback = function
    | Example_finished result ->
        callback result
    | Execution_started | Execution_finished | Group_started _ | Group_finished _ | Example_started _ ->
        ()

end

let exec handlers specs =
  let fire event =
    List.iter (function handle -> handle event) handlers
  in
  let rec exec_spec = function
    | Example (description, example) -> begin
        fire (Example_started description);
        let outcome =
          try
            begin
              example ();
              Pass
            end
          with
          | Expectation_failed (expected, was) ->
              Fail {expected = expected; was = was}
          | e ->
              Error e
        in
        fire (Example_finished (Result (description, outcome)))
      end
    | Group (description, specs) ->
        fire (Group_started description);
        let contextualized = List.map (contextualize description) specs in
        List.iter exec_spec contextualized;
        fire (Group_finished description)
  in
  fire Execution_started;
  List.iter exec_spec specs;
  fire Execution_finished

let eval specs =
  let results = ref [] in
  let remember result =
    results := !results @ [result]
  in
  exec [Handle.each_result remember] specs;
  !results

let console = 
  exec [
    Handle.progress print_char;
    Handle.total_time (Printf.printf "Finished in %f seconds\n");
    Handle.summary
      (fun (passes, failures, errors) ->
        let examples = passes + failures + errors in
        Printf.printf "%d example(s), %d failure(s), %d error(s)\n" examples failures errors
      );
    Handle.failure_report 
      (fun results ->
        let report items = 
          let numbered = items |> List.fold_left (fun results result -> (List.length results + 1, result)::results) [] in
          numbered |> List.iter (fun (i, result) ->
              let format = format_of_string ("  %d) %s\n      %s\n") in
              match result with
              | Result (desc, Pass) -> ()
              | Result (desc, Fail {expected; was}) ->
                  let explanation = Printf.sprintf "Expected %s but was %s" expected was in
                  Printf.printf format i desc explanation
              | Result (desc, Error err) ->
                  let explanation = Printexc.to_string err in
                  Printf.printf format i desc explanation
          )
        in
        let failed = results |> List.filter (function (Result (_, Fail _)) -> true | _ -> false) in
        let errored = results |> List.filter (function (Result (_, Error _)) -> true | _ -> false) in
        begin match failed with
        | [] -> ()
        | _ -> 
            Printf.printf "\nFailures\n\n";
            report failed;
        end;
        begin match errored with
        | [] -> ()
        | _ -> 
            Printf.printf "\nErrors\n\n";
            report errored;
        end;
      );

    Handle.exit_code exit
  ]
