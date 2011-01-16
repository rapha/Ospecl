open Matcher

let less_than limit =
  let description = "less than " ^ (string_of_int limit) in
  let test actual =
    if actual < limit then
      Match (string_of_int actual)
    else
      Mismatch (string_of_int actual)
  in make description test

let not' matcher = 
  let description = "not " ^ description_of matcher in
  let test actual =
    match check actual matcher with
    | Match actual_desc -> Mismatch actual_desc
    | Mismatch actual_desc -> Match actual_desc
  in make description test

let equal_to string_of expected =
  let description = string_of expected in
  let test actual = 
    if expected = actual then
      Match (string_of actual)
    else
      Mismatch (string_of actual)
  in make description test

let approximately epsilon expected =
  let description = "approximately " ^ (string_of_float expected) in
  let test actual =
    if (expected -. actual) < epsilon then
      Match (string_of_float actual)
    else
      Mismatch (string_of_float actual)
  in make description test

let equal_to_int = equal_to string_of_int
let equal_to_string = equal_to (fun s -> s)
let equal_to_bool = equal_to string_of_bool
let equal_to_char = equal_to (fun c -> Printf.sprintf "%c" c)

let has_item matcher = 
  let description = "has item that " ^ description_of matcher in
  let test items = 
    match List.map (fun item -> check item matcher) items with
    | [] -> Mismatch ("no items")
    | (Match _ :: _) as results | Mismatch _ :: results -> begin
        let rec has_item_in = function
          | [] -> Mismatch ("no item " ^ (description_of matcher))
          | Match desc :: _ -> Match desc
          | Mismatch _ :: rest -> has_item_in rest
        in
        has_item_in results
      end 
  in make description test

let every_item matcher = 
  let description = "every item " ^ description_of matcher in
  let test items = 
    match List.map (fun item -> check item matcher) items with
    | [] -> Match "no items"
    | Match _ :: results | (Mismatch _ :: _ as results) -> begin
        let rec every_item_in = function
          | [] -> Match description
          | Match _ :: rest -> every_item_in rest
          | Mismatch desc :: _ -> Mismatch ("has item " ^ desc)
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
    | [] -> Match "no matchers"
    | first :: _ -> begin
        let actual_desc = match check actual first with Match desc -> desc | Mismatch desc -> desc in
        let rec all_of_in = function
          | [] -> Match actual_desc
          | matcher :: rest -> begin
              match check actual matcher with
              | Match _ -> all_of_in rest
              | Mismatch desc -> Mismatch (desc ^ " is not " ^ description_of matcher)
            end
        in all_of_in matchers
      end
  in make description test

let any_of matchers =
  let description = join " or " (List.map description_of matchers) in
  let test actual =
    match matchers with
    | [] -> Mismatch "no matchers"
    | first :: _ -> begin
        let actual_desc = match check actual first with Match desc -> desc | Mismatch desc -> desc in
        let rec any_of_in = function
          | [] -> Mismatch ("none matched " ^ actual_desc)
          | matcher :: rest -> begin
              match check actual matcher with
              | Match desc -> Match (desc ^ " is " ^ description_of matcher)
              | Mismatch _ -> any_of_in rest
            end
        in any_of_in matchers
      end
  in make description test

let has_length expected_length =
  let description = "has length " ^ string_of_int expected_length in
  let test items = 
    let actual_length = List.length items in
    if actual_length = expected_length then
      Match description
    else
      Mismatch ("has length " ^ string_of_int actual_length)
  in make description test
