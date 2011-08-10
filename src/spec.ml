(* private helpers *)

type expectation = Expectation of (unit -> unit) | Pending of string

(* expressing expectations *)
exception Expectation_failed of string

let expect value matcher =
  Expectation begin fun _ ->
    match Matcher.check value matcher with
    | Matcher.Matched _ ->
        ()
    | Matcher.Mismatched desc ->
        (* TODO find difference between descriptions of expected and actual
         * and underline, or otherwise colour those bits of text *)
        let message = Printf.sprintf "Expected %s but got %s" (Matcher.description_of matcher) desc in
        raise (Expectation_failed message)
  end

type t = Example of string list * expectation | Group of string list * t list

let rec contextualise context = function
  | Example (path, expectation) ->
      Example (context @ path, expectation)
  | Group (path, specs) ->
      let full_path = context @ path in
      Group (full_path, List.map (contextualise context) specs)

(* constructing specs *)
let it description expectation = Example ([description], expectation)

let they description_of_actual matcher actuals =
  List.map (fun actual -> it (description_of_actual actual) (expect actual matcher)) actuals

let describe name specs = Group ([name], List.map (contextualise [name]) specs)


let pending blocker = Pending blocker

let (=~) = expect

let join path = match path with
  | [] -> ""
  | first::rest -> List.fold_left (fun result element -> result ^ " " ^ element) first rest

let filter regex specs =
  let description_matches spec = match spec with
    | Example (path, _) -> begin
        let full_description = join path in
        try
          ignore (Str.search_forward regex full_description 0);
          Some spec
        with Not_found ->
          None
      end
    | Group _ ->
        Some spec
  in
  let rec some_values = function
    | [] -> []
    | None :: rest -> some_values rest
    | Some value :: rest -> (value :: some_values rest)
  in
  let rec filter_spec selector spec =
    match spec with
    | Example (path, _) ->
        selector spec
    | Group (path, specs) ->
        let selected = some_values (List.map (filter_spec selector) specs) in
        if selected != [] then
          Some (Group (path, selected))
        else
          None
  in
  some_values (List.map (filter_spec description_matches) specs)

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
          List.iter exec_spec specs;
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

