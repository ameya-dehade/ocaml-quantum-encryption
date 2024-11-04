(*
  FPSE Assignment 1

  Name                  :
  List of Collaborators :

  Please make a good faith effort at listing people you discussed any problems with here, as per the course academic integrity policy.  CAs/Prof need not be listed!

  Note that it is strictly illegal to look for direct answers to these questions using search or AI tools.  For example asking ChatGPT "how do I implement a least common multiple function in OCaml" is illegal.

  Fill in the function definitions below by replacing the 

    unimplemented ()

  with your code. You may add `rec` to any function to make it recursive. You may define any auxillary functions you'd like.

  You must not use any mutation operations of OCaml in this assignment (which we have not taught yet in any case): no arrays, for- or while-loops, references, etc. Also, you may not use the `List` module functions in this assignment, but you may use other standard libraries. In the next assignment, we will start using `List`.

*)

(* Disables "unused variable" warning from dune while you're still solving these! *)
[@@@ocaml.warning "-27"]

(*
  You are required to use core in this class. Don't remove the following line.  If the editor is not recognizing Core (red squiggle under it for example), run a "dune build" from the shell -- the first time you build it will create some .merlin files which tells the editor where the libraries are.
*)
open Core

(*
	All functions must be total for the specified domain;	overflow is excluded from this restriction but should be avoided.
*)

(*
  Given a non-negative integer `n`, compute `0+1+2+ ... +n` using recursion (don't use the closed-form solution, do the actual addition).
*)
let rec summate (n: int) : int =
  match n with
  | 0 -> 0
  | n -> summate(n - 1) + n

let rec gcd (n: int) (m: int) : int =
  match m with
  | 0 -> n
  | _ -> gcd (m)(n % m)

(*
  Given non-negative integers `n` and `m`, compute their least common multiple.
*)
let lcm (n: int) (m: int) : int =
  (n * m) / gcd (n)(m)

(*
  Given a non-negative integer `n`, compute the n-th fibonacci number.	Give an implementation that does not take exponential time; the naive version from lecture is exponential	since it has two recursive calls for each call.
*)
let rec fibonacci (n: int) : int =
  match n with
  | 0 -> 0
  | 1 -> 1
  | n -> fibonacci (n - 1) + fibonacci (n - 2)

(*
  Given non-negative integers `a` and `b`, where `a` is not greater than `b`, produce a list [a; a+1; ...; b-1].
*)
let rec range (a : int) (b : int) : int list =
  match (b - a) with 
  | 0 -> []
  | 1 -> [a]
  | n -> range(a)(b - 1) @ [b - 1]

(*
  Given non-negative integers `n`, `d`, and `k`, produce the arithmetic progression [n; n + d; n + 2d; ...; n + (k-1)d].
*)
let rec arithmetic_progression (n : int) (d : int) (k : int) : int list =
  match k with
  | 0 -> []
  | 1 -> [n]
  | k -> arithmetic_progression(n)(d)(k - 1) @ [n + (k - 1)*d]


let rec factors_helper (n : int) (m : int) : int list =
  if m > n then []
  else if n % m = 0 then m :: factors_helper(n)(m + 1)
  else factors_helper(n)(m + 1)

(*
  Given a positive integer `n`, produce the list of integers in the range (0, n] which it is divisible by, in ascending order.
*)
let factors (n: int) : int list =
  factors_helper n 1

let rec reverse_helper (output : 'a list) (input : 'a list) : 'a list =
  match input with
  | [] -> output
  | (x :: xs) -> reverse_helper (x :: output) xs

(* 
  Reverse a list. Your solution must be in O(n) time. Note: the solution in lecture is O(n^2).
*)
let reverse (ls : 'a list) : 'a list =
  reverse_helper [] ls

(*
  Given a list of strings, check to see if it is ordered, i.e. whether earlier elements are less than or equal to later elements.
*)
let rec is_ordered (ls: string list) : bool =
  match ls with
  | [] | [_] -> true
  | x :: y :: xs -> 
      if String.(x <= y) then is_ordered(y :: xs)
      else false


let rec insert_string_helper (pre: string list) (s: string) (post: string list) : (string list, string) result =
  match post with
  | [] -> Ok(pre @ [s])
  | curr :: xs -> 
      if String.(s > curr) then insert_string_helper (pre @ [curr]) s xs
      else Ok(pre @ [s] @ post)

(*
  Given a string and a list of strings, insert the string into the list so that if the list was originally ordered, then it remains ordered. Return as a result the list with the string inserted.

  If the list is not ordered, then return `Error "insert into unordered list"`.

	Note this is an example of a *functional data structure*, instead of mutating	you return a fresh copy with the element added.
*)
let insert_string (s: string) (ls: string list) : (string list, string) result =
  if not (is_ordered(ls)) then Error "insert into unordered list"
  else insert_string_helper [] s ls


let rec insertion_sort_helper(input: string list) (output: string list) : string list =
  match input with
  | [] -> output
  | s :: xs -> 
      match insert_string s output with
      | Ok new_output -> insertion_sort_helper xs new_output
      | Error _ -> output

(*
	Define a function to sort a list of strings by a functional version of the insertion sort method: repeatedly invoke insert_string to add elements one by one to an initially empty list.

	The sorted list should be sorted from smallest to largest string lexicographically.
*)
let insertion_sort (ls: string list) : string list =
	insertion_sort_helper ls []

(* 
  Split a list `ls` into two pieces, the first of which is the first `n` elements of `ls`,
  and the second is all remaining elements.
  e.g. split_list [1;2;3;4;5] 3 evaluates to ([1;2;3], [4;5])	 
  Note that this function returns a tuple. Here is an example of a tuple.
  ```
  let f x = (x, 10)
  ```
  Assume `n` is non-negative and at most the length of the list.
*)
let rec split_list (ls : 'a list) (n : int) : 'a list * 'a list =
  match (ls, n) with 
  | ([], _) -> ([], [])
  | (l, 0) -> ([], l)
  | (x :: xs, n) ->
       let (left, right) = split_list xs (n - 1) in 
       (x :: left, right)

let rec length (ls: int list) : int =
  match ls with
  | [] -> 0
  | _ :: tail -> 1 + length tail

(* Merge two sorted lists into a single sorted list *)
let rec merge (left : int list) (right : int list) : int list =
  match (left, right) with
  | (_, []) -> left
  | ([], _) -> right
  | (x :: xs, y :: ys) ->
      if x <= y then x :: merge xs right
      else y :: merge left ys

(* 
  Sort an int list using merge sort. Your solution must have time complexity O(n log n). Note that time complexity may depend on your implementation of `split_list`.
*)
let rec merge_sort (ls : int list) = 
  match ls with
  | [] -> []
  | [x] -> [x]
  | _ ->
    let mid = (length ls) / 2 in
    let (left, right) = split_list ls mid in
    merge (merge_sort left) (merge_sort right)

