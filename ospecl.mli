(* a description of component's desired behavour *)
type spec
(* information about how the component conforms to the spec *)
type result = Pass of string | Fail of string | Error of string * exn

(* logical group specs *)
val describe : string -> spec list -> spec
(* build a single spec from a description and test function *)
val it : string -> (unit -> unit) -> spec

(* put expectations in your test functions *)
val expect: 'a -> ('a -> bool) -> unit -> unit

(* execute a spec to get the results *)
val run : spec -> result list
