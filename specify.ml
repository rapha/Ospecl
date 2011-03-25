type spec = Example of string * (unit -> unit) | Group of string * spec list

type outcome = Pass | Fail of string | Error of exn
type result = Result of string * outcome

let it description example = Example (description, example)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Example (description, example) -> Example (context ^ " " ^ description, example)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

exception Expectation_failed of string

let expect value matcher =
  match Matcher.check value matcher with
  | Matcher.Matched _ ->
      ()
  | Matcher.Mismatched desc ->
      let failure_msg = Printf.sprintf "Expected %s but was %s" (Matcher.description_of matcher) desc in
      raise (Expectation_failed failure_msg)
