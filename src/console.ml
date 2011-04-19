open Spec

open Printf

let pluralise noun = function
  | 1 -> noun
  | _ -> (noun ^ "s")

let summary_handler =
  let passes = ref 0 in
  let failures = ref 0 in
  let pending = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Passed _ -> incr passes
      | Failed _ -> incr failures
      | Skipped _ -> incr pending
    end
  | Execution_finished ->
      let examples = !passes + !failures + !pending in
      let message = sprintf "%d %s, %d %s%s\n"
        examples (pluralise "example" examples)
        !failures (pluralise "failure" !failures)
        (if !pending > 0 then (sprintf ", %d %s" !pending "pending") else "")
      in
      print_string message

  | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let total_time_handler =
  let start = ref None in
  let open Spec.Exec in
  function
  | Execution_started ->
      start := Some (Unix.gettimeofday ())
  | Execution_finished ->
      let finish_time = Unix.gettimeofday () in
      begin match !start with
      | None -> failwith "We don't have a start time yet. Execution_finished should not be fired before Execution_started."
      | Some start_time ->
          let duration = finish_time -. start_time in
          printf "Finished in %f seconds\n" duration
      end
  | Group_started _ | Group_finished _ | Example_started _ | Example_finished _ ->
      ()

(* converts a list of items into a list of pairs of (index, item) *)
let indexed items =
  let indices = Array.to_list (Array.init (List.length items) (fun i -> i)) in
  List.combine indices items

let skipped_report_handler =
  let report = ref "\nPending:\n\n" in
  let count = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Skipped (desc, reason) -> begin
          incr count;
          report := !report ^ (sprintf "  %d) %s\n        %s\n\n" !count desc reason)
        end
      | Passed _ | Failed _ -> ()
    end
  | Execution_finished -> begin
      if !count > 0 then
        print_string !report
    end
  | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let failure_report_handler =
  let report = ref "\nFailures:\n\n" in
  let count = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Failed (desc, ex) -> begin
          incr count;
          report := !report ^ (sprintf "  %d) %s\n        %s\n\n" !count desc (Printexc.to_string ex))
        end
      | Passed _ | Skipped _ -> ()
    end
  | Execution_finished -> begin
      if !count > 0 then
        printf "%s" !report
    end
  | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let finish_with_nl_handler = function
  | Exec.Execution_finished -> print_newline ()
  | _ -> ()

let progress_handler =
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Passed _ -> print_char '.'
      | Failed _ -> print_char 'F'
      | Skipped _ -> print_char '*'
    end
  | Execution_started | Execution_finished | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let exit_handler =
  let code = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Failed _ -> code := 1
      | Passed _ | Skipped _ -> ()
    end
  | Execution_finished ->
      exit !code
  | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let progress = Exec.execute [
    progress_handler;
    finish_with_nl_handler;
    skipped_report_handler;
    failure_report_handler;
    total_time_handler;
    summary_handler;
    exit_handler
]

let doc =
  let open Spec.Exec in
  let depth = ref 0 in
  let indent () =
    String.make (!depth*2) ' '
  in
  let doc_handler = function
    | Group_started path -> begin
        let name = List.hd (List.rev path) in
        printf "%s%s\n" (indent ()) name;
        incr depth
      end
    | Group_finished _ ->
        decr depth
    | Example_started path ->
        let description = List.hd (List.rev path) in
        printf "%s%s " (indent ()) description
    | Example_finished result -> begin
        let result =
          match result with
          | Passed _ -> "(PASSED)"
          | Failed _ -> "(FAILED)"
          | Skipped _ -> "(SKIPPED)"
        in
        printf "%s\n" result
      end
    | Execution_started | Execution_finished ->
        ()
  in
  Exec.execute [
    doc_handler;
    finish_with_nl_handler;
    skipped_report_handler;
    failure_report_handler;
    total_time_handler;
    summary_handler;
    exit_handler;
  ]
