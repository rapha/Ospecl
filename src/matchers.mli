val anything : ('a -> string) -> 'a Matcher.t
val is_some : 'a Matcher.t -> 'a option Matcher.t
val whose : (string -> string) -> ('a -> 'b) -> 'b Matcher.t -> 'a Matcher.t
val less_than : int -> int Matcher.t
val not' : 'a Matcher.t -> 'a Matcher.t
val equal_to : ('a -> string) -> 'a -> 'a Matcher.t
val within : float -> float -> float Matcher.t
val equal_to_int : int -> int Matcher.t
val equal_to_string : string -> string Matcher.t
val equal_to_char : char -> char Matcher.t
val equal_to_bool : bool -> bool Matcher.t
val true' : bool Matcher.t
val false' : bool Matcher.t
val equal_to_option : ('a -> string) -> 'a option -> 'a option Matcher.t
val equal_to_list : ('a -> string) -> 'a list -> 'a list Matcher.t
val equal_to_array : ('a -> string) -> 'a array -> 'a array Matcher.t
val has_item : 'a Matcher.t -> 'a list Matcher.t
val every_item : 'a Matcher.t -> 'a list Matcher.t
val all_of : 'a Matcher.t list -> 'a Matcher.t
val any_of : 'a Matcher.t list -> 'a Matcher.t
val length_of : int -> 'a list Matcher.t
val raise_exn : exn -> (unit -> 'a) Matcher.t
val is : 'a -> 'a
val has : 'a -> 'a
val does : 'a -> 'a
