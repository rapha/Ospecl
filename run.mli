(* events that occur during the execution of a spec *)
type execution_event =
  | Execution_started           (* always fired first *)
  | Execution_finished          (* always fired last *)
  | Group_started of string
  | Group_finished of string    (* always fired after corresponding Group_started *)
  | Example_started of string
  | Example_finished of Specify.result  (* always fired after corresponding Example_started *)

(* Listeners respond to execution events *)

(*
 * Handlers must be side-effecting to be useful,
 * which kinda sucks, but not sure how to avoid it.
 *
 * Users (of the lib) can add their own handlers.
 *
 * Event ordering guarantees are as follows:
 * - Execution_started will come first
 * - Execution_finished will come last
 * - Group_finished will come after the corresponding Group_started
 * - Example_finished will come after the corresponding Example_started
 *)

module Handle : sig
  type handler = execution_event -> unit
  val progress : (char -> unit) -> execution_event -> unit
  val total_time : (float -> unit) -> execution_event -> unit
  val summary : ((int * int) -> unit) -> execution_event -> unit
  val exit_code: (int -> unit) -> execution_event -> unit
  val each_result : (Specify.result -> unit) -> execution_event -> unit
end

(* execute specs with the given event listeners *)
val exec : (execution_event -> unit) list -> Specify.spec list -> unit
(* get the results of executing the given specs *)
val eval : Specify.spec list -> Specify.result list

(* typical set of handlers for running from the console *)
val console : Specify.spec list -> unit
