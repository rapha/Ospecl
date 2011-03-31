open Ospecl.Matcher
open Ospecl.Matchers

type point = Point of int * int
let string_of_point (Point (x,y)) =
  "(" ^ string_of_int x ^ "," ^ string_of_int y ^ ")"

let test_less_than () =
  assert (description_of (less_than 3) = "less than 3");
  assert (check 2 (less_than 3) = Matched "2");
  assert (check 3 (less_than 3) = Mismatched "3")

let test_not () =
  assert (description_of (not' (less_than 3)) = "not less than 3");
  assert (check 3 (not' (less_than 3)) = Matched "3");
  assert (check 2 (not' (less_than 3)) = Mismatched "2")

let test_equal_to () =
  let equal_to_point = equal_to string_of_point in
  assert (description_of (equal_to_point (Point (1,2))) = "(1,2)");
  assert (check (Point (1,2)) (equal_to_point (Point (1,2))) = Matched "(1,2)");
  assert (check (Point (1,2)) (equal_to_point (Point (3,4))) = Mismatched "(1,2)")

let test_within () =
  let approx = within 0.001 in
  assert (description_of (approx 0.9) = "within 0.001 of 0.9");
  assert (check 0.9 (approx 0.9) = Matched "0.9");
  assert (check 0.0 (approx (-0.0)) = Matched "0.");
  assert (check infinity (approx infinity) = Matched "inf");
  assert (check neg_infinity (approx neg_infinity) = Matched "-inf");
  assert (check 0.8999999999999999 (approx 0.9) = Matched "0.9");
  assert (check 0.8 (approx 0.9) = Mismatched "0.8")

let test_has_item () =
  assert (description_of (has_item (less_than 5)) = "has item that less than 5");
  assert (check [32; 16; 8; 4; 2] (has_item (less_than 5)) = Matched "4");
  assert (check [32; 16; 8] (has_item (less_than 5)) = Mismatched "no item less than 5");
  assert (check [] (has_item (less_than 5)) = Mismatched "no items")

let test_every_item () =
  assert (description_of (every_item (less_than 5)) = "every item less than 5");
  assert (check [32; 16; 8; 4; 2] (every_item (less_than 5)) = Mismatched "has item 32");
  assert (check [4; 2] (every_item (less_than 5)) = Matched "every item less than 5");
  assert (check [] (every_item (less_than 5)) = Matched "no items")

let test_all_of () =
  let one_to_ten = all_of [(less_than 11); (not' (less_than 1))] in
  assert (description_of one_to_ten = "less than 11 and not less than 1");
  assert (check 4 one_to_ten = Matched "4");
  assert (check 14 one_to_ten = Mismatched "14 is not less than 11");
  assert (check (-6) one_to_ten = Mismatched "-6 is not not less than 1");
  assert (check 1 (all_of []) = Matched "no matchers")

let test_any_of () =
  let not_one_to_ten = any_of [(less_than 1); (not' (less_than 11))] in
  assert (description_of not_one_to_ten = "less than 1 or not less than 11");
  assert (check 4 not_one_to_ten = Mismatched "none matched 4");
  assert (check 14 not_one_to_ten = Matched "14 is not less than 11");
  assert (check (-6) not_one_to_ten = Matched "-6 is less than 1");
  assert (check 1 (any_of []) = Mismatched "no matchers")

let test_length_of () =
  assert (description_of (length_of 2) = "has length 2");
  assert (check [1;2] (length_of 2) = Matched "has length 2");
  assert (check [1] (length_of 2) = Mismatched "has length 1")

let test_raises () =
  assert (description_of (raise_exn (Failure "no")) = "raises Failure(\"no\")");
  assert (check (fun _ -> failwith "no") (raise_exn (Failure "no")) = Matched "raised Failure(\"no\")");
  assert (check (fun _ -> failwith "yes") (raise_exn (Failure "no")) = Mismatched "raised Failure(\"yes\")");
  assert (check (fun _ -> ()) (raise_exn (Failure "no")) = Mismatched "no exception raised")


let _ =
  test_less_than ();
  test_not ();
  test_equal_to ();
  test_within ();
  test_has_item ();
  test_every_item ();
  test_all_of ();
  test_any_of ();
  test_length_of ();
  test_raises ()
