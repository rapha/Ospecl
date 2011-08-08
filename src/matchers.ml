open Matcher

let less_than limit =
  let description = "less than " ^ (string_of_int limit) in
  let test actual =
    if actual < limit then
      Matched (string_of_int actual)
    else
      Mismatched (string_of_int actual)
  in make description test

let not' matcher =
  let description = "not " ^ description_of matcher in
  let test actual =
    match check actual matcher with
    | Matched actual_desc -> Mismatched actual_desc
    | Mismatched actual_desc -> Matched actual_desc
  in make description test

let equal_to string_of expected =
  let description = string_of expected in
  let test actual =
    if expected = actual then
      Matched (string_of actual)
    else
      Mismatched (string_of actual)
  in make description test

let within epsilon expected =
  let description = "within " ^ (string_of_float epsilon) ^ " of " ^ (string_of_float expected) in
  let test actual =
    (* equality check deals with infinities *)
    if expected = actual || (abs_float (expected -. actual)) < epsilon then
      Matched (string_of_float actual)
    else
      Mismatched (string_of_float actual)

  in make description test

let equal_to_int = equal_to string_of_int
let equal_to_string = equal_to (fun s -> s)
let equal_to_char = equal_to (fun c -> Printf.sprintf "%c" c)
let equal_to_bool = equal_to string_of_bool
let true' = equal_to_bool true
let false' = equal_to_bool false

let equal_to_option string_of_item =
  let string_of_option = function
    | None -> "None" 
    | Some item -> "Some (" ^ string_of_item item ^ ")"
  in
  equal_to string_of_option

let rec join = function
  | [] -> ""
  | [item] -> item
  | item :: rest -> item ^ "; " ^ join rest

let equal_to_list string_of_item =
  equal_to (fun items -> "[" ^ join (List.map string_of_item items) ^ "]")

let equal_to_array string_of_item =
  equal_to (fun items -> "[|" ^ join (List.map string_of_item (Array.to_list items)) ^ "|]")

let has_item matcher =
  let description = "has item that " ^ description_of matcher in
  let test items =
    match List.map (fun item -> check item matcher) items with
    | [] -> Mismatched ("no items")
    | (Matched _ :: _) as results | Mismatched _ :: results -> begin
        let rec has_item_in = function
          | [] -> Mismatched ("no item " ^ (description_of matcher))
          | Matched desc :: _ -> Matched desc
          | Mismatched _ :: rest -> has_item_in rest
        in
        has_item_in results
      end
  in make description test

let every_item matcher =
  let description = "every item " ^ description_of matcher in
  let test items =
    match List.map (fun item -> check item matcher) items with
    | [] -> Matched "no items"
    | Matched _ :: results | (Mismatched _ :: _ as results) -> begin
        let rec every_item_in = function
          | [] -> Matched description
          | Matched _ :: rest -> every_item_in rest
          | Mismatched desc :: _ -> Mismatched ("has item " ^ desc)
        in
        every_item_in results
      end
  in make description test

let join separator = function
  | [] -> ""
  | first::rest -> begin
      let rec join_rest so_far = function
        | [] -> so_far
        | item::tail -> join_rest (so_far ^ separator ^ item) tail
      in
      join_rest first rest
    end

let all_of matchers =
  let description = join " and " (List.map description_of matchers) in
  let test actual =
    match matchers with
    | [] -> Matched "no matchers"
    | first :: _ -> begin
        let actual_desc = match check actual first with Matched desc -> desc | Mismatched desc -> desc in
        let rec all_of_in = function
          | [] -> Matched actual_desc
          | matcher :: rest -> begin
              match check actual matcher with
              | Matched _ -> all_of_in rest
              | Mismatched desc -> Mismatched (desc ^ " is not " ^ description_of matcher)
            end
        in all_of_in matchers
      end
  in make description test

let any_of matchers =
  let description = join " or " (List.map description_of matchers) in
  let test actual =
    match matchers with
    | [] -> Mismatched "no matchers"
    | first :: _ -> begin
        let actual_desc = match check actual first with Matched desc -> desc | Mismatched desc -> desc in
        let rec any_of_in = function
          | [] -> Mismatched ("none matched " ^ actual_desc)
          | matcher :: rest -> begin
              match check actual matcher with
              | Matched desc -> Matched (desc ^ " is " ^ description_of matcher)
              | Mismatched _ -> any_of_in rest
            end
        in any_of_in matchers
      end
  in make description test

let length_of expected_length =
  let description = "has length " ^ string_of_int expected_length in
  let test items =
    let actual_length = List.length items in
    if actual_length = expected_length then
      Matched description
    else
      Mismatched ("has length " ^ string_of_int actual_length)
  in make description test

let raise_exn expected =
  let description = "raises " ^ (Printexc.to_string expected) in
  let test func =
    try begin
      func ();
      Mismatched "no exception raised"
    end
    with actual ->
      let message = "raised " ^ Printexc.to_string actual in
      if actual = expected then
        Matched message
      else
        Mismatched message
  in make description test

let is matcher = matcher
let has matcher = matcher
let does matcher = matcher
