type match_result = Match of string | Mismatch of string

type 'a t = {
  description: string;
  test: 'a -> match_result
}

let make desc test =
  { description = desc; test = test }

let description_of { description = desc } = desc
let check actual { test = test } = test actual
