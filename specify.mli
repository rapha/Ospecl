(* an executable description of a component's desired behavour *)
type spec = private Example of string * (unit -> unit) | Group of string * spec list

(* exception raised when an expectation is not met *)
exception Expectation_failed of string

(* information about how the component conforms to the spec *)
type outcome =  Pass | Fail of exn
type result = Result of string * outcome

(* build a single spec from a description and test function *)
val it : string -> (unit -> unit) -> spec
(* logically group specs *)
val describe : string -> spec list -> spec

(* add context to the description of a spec *)
val contextualize : string -> spec -> spec


(* put expectations about values in your test functions *)
val should : 'a Matcher.t -> 'a -> unit

(* used togeter with should, e.g. 1 + 1 |> should (be (equal_to 2)) *)
val be : 'a Matcher.t -> 'a Matcher.t
val (|>) : 'a -> ('a -> 'b) -> 'b
