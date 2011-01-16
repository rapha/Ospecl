type 'a t

type match_result = Match of string | Mismatch of string

val make : string -> ('a -> match_result) -> 'a t

val check : 'a -> 'a t -> match_result
val description_of : 'a t -> string
