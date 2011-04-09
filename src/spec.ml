(* constructing specs *)
type expectation = Expectation of (unit -> unit) | Pending of string

type t = Example of string list * expectation | Group of string list * t list

let it description expectation = Example ([description], expectation)
let describe name specs = Group ([name], specs)

let join path = match path with
  | [] -> ""
  | first::rest -> List.fold_left (fun result element -> result ^ " " ^ element) first rest

let contextualize context = function
  | Example (path, expectation) -> Example (context @ path, expectation)
  | Group (path, specs) -> Group (context @ path, specs)

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
type result = Passed of string | Failed of string * exn | Skipped of string * string

module Exec = struct
  type path = string list

  type event =
    | Execution_started
    | Execution_finished
    | Group_started of path
    | Group_finished of path
    | Example_started of path
    | Example_finished of result

  type handler = (event -> unit)

  let execute handlers specs =
    let fire event =
      List.iter (function handle -> handle event) handlers
    in
    let rec exec_spec = function
      | Example (path, expectation) -> begin
          let description = join path in
          fire (Example_started path);
          let result =
            match expectation with
            | Expectation example ->
                begin 
                  try
                    example ();
                    Passed description
                  with
                  | ex ->
                      Failed (description, ex)
                end
            | Pending blocker ->
                Skipped (description, blocker)
          in
          fire (Example_finished result)
        end
      | Group (path, specs) ->
          fire (Group_started path);
          let contextualized = List.map (contextualize path) specs in
          List.iter exec_spec contextualized;
          fire (Group_finished path)
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
