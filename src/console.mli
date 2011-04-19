(* run specs, printing progress and results to stdout, and exit *)
val progress: color:bool -> Spec.t list -> unit
(* run specs, printing spec descriptions and results to stdout, and exit *)
val documentation: color:bool -> Spec.t list -> unit
