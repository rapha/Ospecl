open Spec

open Printf

let normal_text = "[0m"
let red_text text = "[31m" ^ text ^ normal_text
let yellow_text text = "[33m" ^ text ^ normal_text
let green_text text = "[32m" ^ text ^ normal_text
let grey_text text = "[90m" ^ text ^ normal_text

let color_of = function
  | Passed _ -> green_text
  | Skipped _ -> yellow_text
  | Failed _ -> red_text

let pluralise noun = function
  | 1 -> noun
  | _ -> (noun ^ "s")

let summary_handler color =
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
      let text_color = (if !failures > 0 then red_text else if !pending > 0 then yellow_text else green_text) in
      print_string (if color then text_color message else message); 
      print_string (normal_text);
      flush stdout

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


let skipped_report_handler color =
  let report = ref "\nPending:\n\n" in
  let count = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Skipped (desc, reason) -> begin
          incr count;
          report := !report ^ (sprintf "  %s\n    %s\n\n"
            (if color then yellow_text desc else desc)
            (if color then grey_text reason else reason))
        end
      | Passed _ | Failed _ -> ()
    end
  | Execution_finished -> begin
      if !count > 0 then
        print_string !report
    end
  | Execution_started | Group_started _ | Group_finished _ | Example_started _ ->
      ()

let failure_report_handler color =
  let report = ref "\nFailures:\n\n" in
  let count = ref 0 in
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      match result with
      | Failed (desc, ex) -> begin
          incr count;
          let error_msg = Printexc.to_string ex in
          report := !report ^ (sprintf "  %d) %s\n        %s\n\n" 
            !count 
            desc 
            (if color then red_text error_msg else error_msg))
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

let progress_handler color =
  let open Spec.Exec in
  function
  | Example_finished result -> begin
      let str = 
        match result with
        | Passed _ -> "."
        | Skipped _ -> "*"
        | Failed _ -> "F"
      in
      print_string (if color then color_of result str else str)
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

let progress ~color = [
  progress_handler color;
  finish_with_nl_handler;
  skipped_report_handler color;
  failure_report_handler color;
  total_time_handler;
  summary_handler color;
  exit_handler
]

let documentation ~color =
  let open Spec.Exec in
  let depth = ref 0 in
  let name = ref "" in
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
        name := description
    | Example_finished result -> begin
        let message =
          match result with
          | Passed _ -> !name
          | Failed _ -> sprintf "%s (FAILED)" !name
          | Skipped (_, reason) -> sprintf "%s (PENDING: %s)" !name reason
        in
        printf "%s%s\n" (indent ()) (if color then color_of result message else message)
      end
    | Execution_started | Execution_finished ->
        ()
  in
  [
    doc_handler;
    finish_with_nl_handler;
    skipped_report_handler color;
    failure_report_handler color;
    total_time_handler;
    summary_handler color;
    exit_handler;
  ]
