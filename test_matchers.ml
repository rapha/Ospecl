open Matcher
open Matchers

type point = Point of int * int
let string_of_point (Point (x,y)) =
  "(" ^ string_of_int x ^ "," ^ string_of_int y ^ ")"

let test_less_than () =
  assert (description_of (less_than 3) = "less than 3");
  assert (check 2 (less_than 3) = Match "2");
  assert (check 3 (less_than 3) = Mismatch "3")

let test_not () =
  assert (description_of (not' (less_than 3)) = "not less than 3");
  assert (check 3 (not' (less_than 3)) = Match "3");
  assert (check 2 (not' (less_than 3)) = Mismatch "2")

let test_equal_to () =
  assert (description_of (equal_to string_of_point (Point (1,2))) = "(1,2)");
  assert (check (Point (1,2)) (equal_to string_of_point (Point (1,2))) = Match "(1,2)");
  assert (check (Point (1,2)) (equal_to string_of_point (Point (3,4))) = Mismatch "(1,2)")

let test_approximately () =
  let approxPoint9 = (approximately 0.000001 0.9) in
  assert (description_of approxPoint9 = "approximately 0.9");
  assert (check 0.8999999999999999 approxPoint9 = Match "0.9");
  assert (check 0.8 approxPoint9 = Mismatch "0.8")

let test_has_item () =
  assert (description_of (has_item (less_than 5)) = "has item that less than 5");
  assert (check [32; 16; 8; 4; 2] (has_item (less_than 5)) = Match "4");
  assert (check [32; 16; 8] (has_item (less_than 5)) = Mismatch "no item less than 5");
  assert (check [] (has_item (less_than 5)) = Mismatch "no items")

let test_every_item () =
  assert (description_of (every_item (less_than 5)) = "every item less than 5");
  assert (check [32; 16; 8; 4; 2] (every_item (less_than 5)) = Mismatch "has item 32");
  assert (check [4; 2] (every_item (less_than 5)) = Match "every item less than 5");
  assert (check [] (every_item (less_than 5)) = Match "no items")

let test_all_of () =
  let one_to_ten = all_of [(less_than 11); (not' (less_than 1))] in
  assert (description_of one_to_ten = "less than 11 and not less than 1");
  assert (check 4 one_to_ten = Match "4");
  assert (check 14 one_to_ten = Mismatch "14 is not less than 11");
  assert (check (-6) one_to_ten = Mismatch "-6 is not not less than 1");
  assert (check 1 (all_of []) = Match "no matchers")

let test_any_of () =
  let not_one_to_ten = any_of [(less_than 1); (not' (less_than 11))] in
  assert (description_of not_one_to_ten = "less than 1 or not less than 11");
  assert (check 4 not_one_to_ten = Mismatch "none matched 4");
  assert (check 14 not_one_to_ten = Match "14 is not less than 11");
  assert (check (-6) not_one_to_ten = Match "-6 is less than 1");
  assert (check 1 (any_of []) = Mismatch "no matchers")

let test_has_length () =
  assert (description_of (has_length 2) = "has length 2");
  assert (check [1;2] (has_length 2) = Match "has length 2");
  assert (check [1] (has_length 2) = Mismatch "has length 1")

let _ =
  test_less_than ();
  test_not ();
  test_equal_to ();
  test_approximately ();
  test_has_item ();
  test_every_item ();
  test_all_of ();
  test_any_of ();
  test_has_length ();
