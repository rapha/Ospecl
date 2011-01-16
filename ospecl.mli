(* an executable description of a component's desired behavour *)
type spec
(* information about how the component conforms to the spec *)
type outcome =  Pass | Fail of string | Error of exn
type result = Result of string * outcome
(* events that occur during the execution of a spec *)
type exec_event =
  | Describe_started of string
  | Describe_finished of string
  | It_started of string
  | It_finished of result

(* build a single spec from a description and test function *)
val it : string -> (unit -> unit) -> spec
(* logically group specs *)
val describe : string -> spec list -> spec

(* put expectations about values in your test functions *)
val expect: 'a -> 'a Matcher.t -> unit -> unit

(* execute a spec with the given event listeners *)
val exec: (exec_event -> unit) list -> spec -> unit
(* evaluate a spec to get a list of the results *)
val eval: spec -> result list
