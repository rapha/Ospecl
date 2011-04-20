(* run specs, printing progress and results to stdout, and exit *)
val progress: matching:Str.regexp -> color:bool -> Spec.t list -> unit
(* run specs, printing spec descriptions and results to stdout, and exit *)
val documentation: matching:Str.regexp -> color:bool -> Spec.t list -> unit
