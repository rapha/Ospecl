open Spec

module Handlers = struct
  open Spec.Exec

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
    let skips = ref 0 in
    function
    | Example_finished result -> begin
        match result with
        | Passed _ -> incr passes
        | Failed _ -> incr failures
        | Skipped _ -> incr skips
      end
    | Execution_finished ->
        callback (!passes, !failures, !skips)
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let failure_report callback =
    let failures = ref [] in
    function
    | Example_finished result -> begin
        match result with
        | Passed _ -> ()
        | Failed _ -> failures := result :: !failures
        | Skipped _ -> ()
      end
    | Execution_finished ->
        callback (List.rev !failures)
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let exit_code callback =
    let code = ref 0 in
    function
    | Example_finished result -> begin
        match result with
        | Passed _ -> ()
        | Failed _ -> code := 1
        | Skipped _ -> ()
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

let console = 
  Exec.execute [
    Handlers.each_result (function
      | Passed _ -> print_char '.'
      | Failed _ -> print_char 'F'
      | Skipped _ -> print_char '*'
    );
    (function Exec.Execution_finished -> print_newline () | _ -> ());
    Handlers.failure_report 
      (fun results ->
        let indexed items = 
          let indices = Array.to_list (Array.init (List.length items) (fun i -> i)) in
          List.combine indices items 
        in
        let report (index, result) = 
          match result with
          | Passed _ -> ()
          | Failed (desc, ex) ->
              Printf.printf "  %d) %s\n        %s\n\n" (index+1) desc (Printexc.to_string ex)
          | Skipped _ -> ()
        in
        let failed = List.filter (function Failed _ -> true | _ -> false) results in
        if List.length failed > 0 then
          Printf.printf "\nFailures:\n\n";
          List.iter report (indexed failed)
      );
    Handlers.total_time (Printf.printf "Finished in %f seconds\n");
    Handlers.summary
      (fun (passes, failures, pending) ->
        let examples = passes + failures in
        let pluralise noun = function
          | 1 -> noun
          | _ -> (noun ^ "s")
        in
        Printf.printf "%d %s, %d %s\n" examples (pluralise "example" examples) failures (pluralise "failure" failures)
      );

    Handlers.exit_code exit
  ]
