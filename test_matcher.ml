open Printf

let _ =
  let module M = Ospecl.Matcher in
  let is_even = M.make "is even" (fun n ->
    if n mod 2 = 0 then M.Matched "even" else M.Mismatched "odd"
  ) in
  assert (M.description_of is_even = "is even");
  assert (M.check 2 is_even = M.Matched "even");
  assert (M.check 1 is_even = M.Mismatched "odd");

