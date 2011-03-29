open Specify

type execution_event =
  | Execution_started
  | Execution_finished
  | Group_started of string
  | Group_finished of string
  | Example_started of string
  | Example_finished of result

type handler = execution_event -> unit

module Handlers = struct
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
    function
    | Example_finished (Result (_, outcome)) -> begin
        match outcome with
        | Pass -> incr passes
        | Fail _ -> incr failures
      end
    | Execution_finished ->
        callback (!passes, !failures)
    | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
        ()

  let failure_report callback =
    let failures = ref [] in
    function
    | Example_finished (Result (_, outcome) as r) -> begin
        match outcome with
        | Pass -> ()
        | Fail _ -> failures := r :: !failures
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
        | Fail _ -> code := 1
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
          | e ->
              let backtrace = Printexc.get_backtrace () in
              Fail (e,backtrace)
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
  exec [Handlers.each_result remember] specs;
  !results

let console = 
  exec [
    Handlers.each_result (function
      | Result (_, Pass) -> print_char '.'
      | Result (_, Fail _) -> print_char 'F'
    );
    (function Execution_finished -> print_newline () | _ -> ());
    Handlers.failure_report 
      (fun results ->
        let indexed items = 
          let indices = Array.init (List.length items) (fun i -> i) |> Array.to_list in
          List.combine indices items 
        in
        let report (index, result) = 
          match result with
          | Result (_, Pass) -> ()
          | Result (desc, Fail (ex, trace)) ->
              Printf.printf "  %d) %s\n\n" (index+1) desc
        in
        let failed = results |> List.filter (function (Result (_, Fail _)) -> true | _ -> false) in
        if List.length failed > 0 then
          Printf.printf "\nFailures:\n\n";
          failed |> indexed |> List.iter report
      );
    Handlers.total_time (Printf.printf "Finished in %f seconds\n");
    Handlers.summary
      (fun (passes, failures) ->
        let examples = passes + failures in
        let pluralise noun = function
          | 1 -> noun
          | _ -> (noun ^ "s")
        in
        Printf.printf "%d %s, %d %s\n" examples (pluralise "example" examples) failures (pluralise "failure" failures)
      );

    Handlers.exit_code exit
  ]
