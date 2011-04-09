(* events that occur during the execution of a spec *)
module Handlers : sig
  (* passes the total duration (in seconds) to the given function once execution has finished *)
  val total_time : (float -> unit) -> Spec.Exec.handler
  (* passes the count of passes and failures to the given function at the end *)
  val summary : ((int * int * int) -> unit) -> Spec.Exec.handler
  (* passes the appropriate exit code (1 for any failures, 0 for all passes) to the given function at the end *)
  val exit_code: (int -> unit) -> Spec.Exec.handler
  (* passes each result to the given function as they occur *)
  val each_result : (Spec.result -> unit) -> Spec.Exec.handler
end

(* default set of handlers for running from the console *)
val console : Spec.t list -> unit

val doc: Spec.t list -> unit
