type spec = Example of string * (unit -> unit) | Group of string * spec list

type failure_description = {expected: string; was: string}
exception Expectation_failed of string * string

type outcome = Pass | Fail of failure_description | Error of exn
type result = Result of string * outcome

let it description example = Example (description, example)
let describe name specs = Group (name, specs)

let contextualize context spec = match spec with
  | Example (description, example) -> Example (context ^ " " ^ description, example)
  | Group (description, specs) -> Group (context ^ " " ^ description, specs)

let should matcher value =
  match Matcher.check value matcher with
  | Matcher.Matched _ ->
      ()
  | Matcher.Mismatched desc ->
      raise (Expectation_failed (Matcher.description_of matcher, desc))

let (|>) x f = f x
let be matcher = matcher
