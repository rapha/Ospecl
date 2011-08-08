(* an executable description of a component's desired behavour *)
type t
type expectation

(* information about how the component conforms to the spec *)
type result =  Passed of string | Failed of string * exn | Skipped of string * string

(* build a single spec from a description an expectation *)
val it : string -> expectation -> t
(* build a list of specs from a single matcher which a list of values must match *)
val they : ('a -> string) -> 'a Matcher.t -> 'a list -> t list
(* logically group specs *)
val describe : string -> t list -> t

(* make expectations about values *)
val expect : 'a -> 'a Matcher.t -> expectation
val (=~) : 'a -> 'a Matcher.t -> expectation
val pending : string -> expectation

(* Filters a list of specs, removing: 
 *   all examples whose description does not match the regex
 *   all groups which do not contain any matching examples
 *)
val filter : Str.regexp -> t list -> t list

(* get the results of executing a spec *)
val eval : t -> result list

module Exec : sig
  (* the descriptions which trace the path to a given spec *)
  type path = string list

  (* events that occur during the execution of a spec *)
  type event =
    | Execution_started           (* always fired first *)
    | Execution_finished          (* always fired last *)
    | Group_started of path
    | Group_finished of path      (* always fired after corresponding Group_started *)
    | Example_started of path
    | Example_finished of result  (* always fired after corresponding Example_started *)

  (* handlers are executed to respond to execution events *)
  type handler = (event -> unit)

  (* execute specs matching the regexp with the given event handlers *)
  val execute : handler list -> t list -> unit
end
