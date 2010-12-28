(* an executable description of a component's desired behavour *)
type spec
(* information about how the component conforms to the spec *)
type result = Pass of string | Fail of string | Error of string * exn

(* build a single spec from a description and test function *)
val it : string -> (unit -> unit) -> spec
(* logically group specs *)
val describe : string -> spec list -> spec

(* put expectations about values in your test functions *)
val expect: 'a -> ('a -> bool) -> unit -> unit

(* execute a spec to get the results *)
val run : spec -> result list
