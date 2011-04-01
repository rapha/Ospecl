(* constructing specs *)
type expectation = Expectation of (unit -> unit) | Pending of string

type t = Example of string * expectation | Group of string * t list

let it description expectation = Example (description, expectation)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Example (description, expecation) -> Example (context ^ " " ^ description, expecation)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

(* expressing expectations *)
exception Expectation_failed of string

let expect value matcher =
  Expectation begin fun _ ->
    match Matcher.check value matcher with
    | Matcher.Matched _ ->
        ()
    | Matcher.Mismatched desc ->
        let message = Printf.sprintf "Expected %s but got %s" (Matcher.description_of matcher) desc in
        raise (Expectation_failed message)
  end

let pending blocker = Pending blocker

let (=~) = expect

(* executing the specs *)
type result = Pass of string | Fail of string * exn | Skip of string * string

module Exec = struct
  type event =
    | Execution_started
    | Execution_finished
    | Group_started of string
    | Group_finished of string
    | Example_started of string
    | Example_finished of result

  type handler = (event -> unit)

  let execute handlers specs =
    let fire event =
      List.iter (function handle -> handle event) handlers
    in
    let rec exec_spec = function
      | Example (description, expectation) -> begin
          fire (Example_started description);
          let result =
            match expectation with
            | Expectation example ->
                begin 
                  try
                    example ();
                    Pass description
                  with
                  | ex ->
                      Fail (description, ex)
                end
            | Pending blocker ->
                Skip (description, blocker)
          in
          fire (Example_finished result)
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

end

let eval specs =
  let results = ref [] in
  Exec.execute [(function
    | Exec.Example_finished result -> results := (result :: !results)
    | _ -> ()
  )] [specs];
  List.rev !results
