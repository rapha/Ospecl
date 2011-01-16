open Ospecl

let console spec =
  let results = eval spec in
  let (passed, failed, errored) = List.fold_left (fun (p, f, e) result -> 
    match result with
    | Result (_, Pass) -> (p+1, f, e)
    | Result (_, Fail _) -> (p, f+1, e)
    | Result (_, Error _) -> (p, f, e+1)
  ) (0, 0, 0) results in
  let success = (failed = 0 && errored = 0) in

  Printf.printf "Build %s. Passed: %d, Failed: %d, Errored: %d.\n" 
    (if success then "successful" else "failed") passed failed errored;

  let exit_code = 0 + 
    (if failed > 0 then 1 else 0) + 
    (if errored > 0 then 2 else 0)
  in
  exit exit_code

  
