type spec = Example of string * (unit -> unit) | Group of string * spec list

exception Expectation_failed of string

type result = Pass of string | Fail of string * exn

let it description example = Example (description, example)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Example (description, example) -> Example (context ^ " " ^ description, example)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

let apply matcher value =
  match Matcher.check value matcher with
  | Matcher.Matched _ ->
      ()
  | Matcher.Mismatched desc ->
      let message = Printf.sprintf "Expected %s but got %s" (Matcher.description_of matcher) desc in
      raise (Expectation_failed message)

let (|>) x f = f x
let is = apply
let has = apply
let does = apply
