(* events that occur during the execution of a spec *)
type execution_event =
  | Execution_started           (* always fired first *)
  | Execution_finished          (* always fired last *)
  | Group_started of string
  | Group_finished of string    (* always fired after corresponding Group_started *)
  | Example_started of string
  | Example_finished of Specify.result  (* always fired after corresponding Example_started *)

(*
 * Handlers respond to execution events.
 * They must be side-effecting to be useful. 
 * Users may use their own custom handlers too.
 *)
type handler = execution_event -> unit

module Handlers : sig
  (* passes the total duration (in seconds) to the given function once execution has finished *)
  val total_time : (float -> unit) -> handler
  (* passes the count of passes and failures to the given function at the end *)
  val summary : ((int * int) -> unit) -> handler
  (* passes the appropriate exit code (1 for any failures, 0 for all passes) to the given function at the end *)
  val exit_code: (int -> unit) -> handler
  (* passes each result to the given function as they occur *)
  val each_result : (Specify.result -> unit) -> handler
end

(* execute specs with the given event listeners *)
val exec : handler list -> Specify.spec list -> unit
(* get the results of executing the given specs *)
val eval : Specify.spec list -> Specify.result list

(* typical set of handlers for running from the console *)
val console : Specify.spec list -> unit
