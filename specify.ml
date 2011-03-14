type spec = Example of string * (unit -> unit) | Group of string * spec list

type outcome = Pass | Fail of string | Error of exn
type result = Result of string * outcome

type execution_event =
  | Group_started of string
  | Group_finished of string
  | Example_started of string
  | Example_finished of result

exception Expectation_failed of string

let (|>) x f = f x

let it description test_function = Example (description, test_function)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Example (description, test_function) -> Example (context ^ " " ^ description, test_function)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

let rec exec listeners specs =
  let fire event = listeners |> List.iter ((|>) event) in
  List.iter (function
    | Example (description, test_function) -> begin
        try
          begin
            fire (Example_started description);
            test_function();
            fire (Example_finished (Result (description, Pass)))
          end
        with
        | Expectation_failed failure -> fire (Example_finished (Result (description, Fail failure)))
        | e -> fire (Example_finished (Result (description, Error e)))
      end
    | Group (description, specs) ->
        fire (Group_started description);
        specs |> List.map (contextualize description) |> exec listeners;
        fire (Group_finished description)
  ) specs

let eval specs =
  let results = ref [] in
  let recording_listener = function
    | Example_finished result -> results := (result :: !results)
    | Group_started _ | Group_finished _ | Example_started _ -> ()
  in exec [recording_listener] specs;
  List.rev !results

let expect value matcher =
  match Matcher.check value matcher with
  | Matcher.Matched _ ->
      ()
  | Matcher.Mismatched desc ->
      let failure_msg = Printf.sprintf "Expected %s but was %s" (Matcher.description_of matcher) desc in
      raise (Expectation_failed failure_msg)
