type spec = Single of string * (unit -> unit) | Group of string * spec list

type result = Pass of string | Fail of string | Error of string * exn

exception Expectation_failed

let it description func = Single (description, func)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Single (description, func) -> Single (context ^ " " ^ description, func)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

let rec run spec = match spec with
  | Single (description, func) -> begin
      try 
        begin
          func(); 
          [Pass description]
        end 
      with 
      | Expectation_failed -> [Fail description]
      | e -> [Error (description, e)]
    end
  | Group (description, specs) -> 
      List.concat (List.map run (List.map (contextualize description) specs))

let expect value predicate () =
  if predicate value then 
    () 
  else 
    raise Expectation_failed
