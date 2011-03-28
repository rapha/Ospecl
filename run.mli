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
 *
 * They must be side-effecting to be useful, 
 * which kinda sucks but I'm not sure how to avoid it.
 *
 * Users (of the lib) can use their own handlers too.
 *
 * Event ordering guarantees are as follows:
 * - Execution_started will come first
 * - Execution_finished will come last
 * - Group_finished will come after the corresponding Group_started
 * - Example_finished will come after the corresponding Example_started
 *)

module Handler : sig
  type handler = execution_event -> unit
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
val exec : (execution_event -> unit) list -> Specify.spec list -> unit
(* get the results of executing the given specs *)
val eval : Specify.spec list -> Specify.result list

(* typical set of handlers for running from the console *)
val console : Specify.spec list -> unit
