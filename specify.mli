(* an executable description of a component's desired behavour *)
type spec = private Example of string * (unit -> unit) | Group of string * spec list

(* information about how the component conforms to the spec *)
type outcome =  Pass | Fail of exn
type result = Result of string * outcome

(* build a single spec from a description and test function *)
val it : string -> (unit -> unit) -> spec
(* logically group specs *)
val describe : string -> spec list -> spec

(* add context to the description of a spec *)
val contextualize : string -> spec -> spec

(* 
 * Handy functions to pass values to matchers in a somewhat literate style
 *
 * e.g.
 * 1 + 1 |> is (less_than 3)
 * [1;2;3] |> has (all_of [every_item (less_than 5); length_of 3])
 * (fun _ -> failwith "no") |> does (raise_exn (Failure "no"))
 *)
val is: 'a Matcher.t -> 'a -> unit
val has: 'a list Matcher.t -> 'a list -> unit
val does: 'a Matcher.t -> 'a -> unit
val (|>) : 'a -> ('a -> 'b) -> 'b
