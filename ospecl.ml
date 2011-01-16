type spec = Single of string * (unit -> unit) | Group of string * spec list

type outcome = Pass | Fail of string | Error of exn
type result = Result of string * outcome

type exec_event =
  | Describe_started of string
  | Describe_finished of string
  | It_started of string
  | It_finished of result

exception Expectation_failed of string

let (|>) x f = f x

let it description test_function = Single (description, test_function)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Single (description, test_function) -> Single (context ^ " " ^ description, test_function)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

let rec exec listeners spec = 
  let fire event = listeners |> List.iter ((|>) event) in
  match spec with
  | Single (description, test_function) -> begin
      try 
        begin
          fire (It_started description);
          test_function(); 
          fire (It_finished (Result (description, Pass)))
        end 
      with 
      | Expectation_failed failure -> fire (It_finished (Result (description, Fail failure)))
      | e -> fire (It_finished (Result (description, Error e)))
    end
  | Group (description, specs) -> 
      fire (Describe_started description); 
      specs |> List.map (contextualize description) |> List.iter (exec listeners);
      fire (Describe_finished description)

let eval spec =
  let results = ref [] in
  let recording_listener = function
    | It_finished result -> results := (result :: !results)
    | Describe_started _ | Describe_finished _ | It_started _ -> ()
  in exec [recording_listener] spec;
  List.rev !results

let expect value matcher () =
  match Matcher.check value matcher with
  | Matcher.Match _ -> ()
  | Matcher.Mismatch desc -> raise (Expectation_failed (Printf.sprintf "Expected %s but was %s" (Matcher.description_of matcher) desc))
