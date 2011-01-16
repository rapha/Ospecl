open Printf

open Matcher

let print_match_result = function
  | Match desc -> printf "Match %s\n" desc
  | Mismatch desc -> printf "Mismatch (%s)\n" desc

let _ =
  let is_even n = if n mod 2 = 0 then Match "even" else Mismatch "odd" in
  let even = make "is even" is_even in
  assert (description_of even = "is even");
  assert (check 2 even = Match "even");
  assert (check 1 even = Mismatch "odd");
