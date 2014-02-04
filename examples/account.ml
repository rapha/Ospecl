type t = int

exception Insufficient_funds of int

let create () = 0

let balance account = account

let deposit amount account =
  match amount with
  | neg when amount < 0 ->
      invalid_arg (Printf.sprintf "Cannot deposit a negative amount: %d" amount)
  | pos ->
      amount + account

let withdraw amount account =
  match amount with
  | neg when amount < 0 ->
      invalid_arg (Printf.sprintf "Cannot withdraw a negative amount: %d" amount)
  | pos when amount > account ->
      raise (Insufficient_funds account)
  | pos ->
      account - amount
