(* run specs, printing progress and results to stdout, and exit *)
val progress: Spec.t list -> unit
(* run specs, printing spec descriptions and results to stdout, and exit *)
val documentation: Spec.t list -> unit
