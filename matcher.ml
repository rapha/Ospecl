type match_result = Matched of string | Mismatched of string

type 'a t = {
  description: string;
  test: 'a -> match_result
}

let make desc test =
  { description = desc; test = test }

let description_of { description = desc } = desc
let check actual { test = test } = test actual
