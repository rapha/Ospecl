module Terminal : sig
  (* run specs, printing progress and results to stdout, and exit *)
  val progress: color:bool -> Spec.Exec.handler list
  (* run specs, printing spec descriptions and results to stdout, and exit *)
  val documentation: color:bool -> Spec.Exec.handler list
end
