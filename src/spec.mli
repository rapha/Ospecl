(* an executable description of a component's desired behavour *)
type t
type expectation

(* information about how the component conforms to the spec *)
type result =  Passed of string | Failed of string * exn | Skipped of string * string

(* build a single spec from a description and test function *)
val it : string -> expectation -> t
(* logically group specs *)
val describe : string -> t list -> t

(* make expectations about values *)
val expect : 'a -> 'a Matcher.t -> expectation
val (=~) : 'a -> 'a Matcher.t -> expectation

(* get the results of executing a spec *)
val eval : t -> result list

module Exec : sig
  (* events that occur during the execution of a spec *)
  type event =
    | Execution_started           (* always fired first *)
    | Execution_finished          (* always fired last *)
    | Group_started of string
    | Group_finished of string    (* always fired after corresponding Group_started *)
    | Example_started of string
    | Example_finished of result  (* always fired after corresponding Example_started *)

  (* handlers are executed to respond to execution events *)
  type handler = (event -> unit)

  (* execute specs with the given event handlers *)
  val execute : handler list -> t list -> unit
end
