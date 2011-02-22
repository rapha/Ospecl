open Specify

let console specs =
  let results = eval specs in
  let (output, passed, failed, errored) = List.fold_left (fun (out, p, f, e) result -> 
    match result with
    | Result (_, Pass) -> 
        (out, p+1, f, e)
    | Result (desc, Fail problem) -> 
        let fail_line = Printf.sprintf "FAIL: '%s' because '%s'\n" desc problem in
        (out ^ fail_line, p, f+1, e)
    | Result (desc, Error ex) -> 
        let error_line = Printf.sprintf "ERROR: '%s'\n" desc in
        (out ^ error_line, p, f, e+1)
  ) ("", 0, 0, 0) results in
  let success = (failed = 0 && errored = 0) in

  let summary = Printf.sprintf "Build %s. Passed: %d, Failed: %d, Errored: %d.\n" 
    (if success then "successful" else "failed") passed failed errored in

  let exit_code = 0 + 
    (if failed > 0 then 1 else 0) + 
    (if errored > 0 then 2 else 0)
  in

  print_endline (output ^ summary);
  exit exit_code

  
