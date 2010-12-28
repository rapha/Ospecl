type spec = Describe of string * spec list | It of string * (unit -> unit)
type result = Pass of string | Fail of string | Error of string * exn
exception Check_failed

let (|>) x f = f x

let it description func = It (description, func)
let describe name specs = Describe (name, specs)

let contextualize context spec = match spec with
  | It (description, func) -> It (context ^ " " ^ description, func)
  | Describe (description, specs) -> Describe (context ^ " " ^ description, specs)

let rec run spec = match spec with
  | It (description, func) -> begin
      try 
        begin
          func(); 
          [Pass description]
        end 
      with 
      | Check_failed -> [Fail description]
      | e -> [Error (description, e)]
    end
  | Describe (description, specs) -> 
      specs |> List.map (contextualize description) |> List.map run |> List.concat

let expect value predicate () =
  if predicate value then 
    () 
  else 
    raise Check_failed
