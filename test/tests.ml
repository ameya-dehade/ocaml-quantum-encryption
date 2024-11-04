open OUnit2
open Submission

(* 
  This file contains a few tests, but it is not necessarily complete coverage.
  You are encouraged to think of more tests for the corner cases.
  We will cover the test syntax in more detail later, but a simple copy/paste here should
  allow you to write your own additional tests without knowing the details.
   1) Write a new let which performs the test, e.g. let test_fibonacci_2 _ = ...
   2) Add that let-named entity to one of the test suite lists such as int_tests
      by adding e.g.
       "Fibonacci 2"  >:: test_fibonacci_2;
   Thats it!

   Recall that you need to type "dune test" to your shell to run the test suite.
*)

(*
  This is a test function. It takes an unused argument `_` so that the body can be evaluated later.   
*)
let test_summate _ =
  assert_equal (summate 3) 6; (* the semicolon is an expression separator and must be used between your `assert_equal` statements *)
  assert_equal (summate 10) 55 (* note a semicolon is illegal here. The statement list must end without a semicolon *)
  
let test_lcm _ =
  assert_equal (lcm 3 9) 9;
  assert_equal (lcm 9 12) 36

let test_fibonacci _ =
  assert_equal (fibonacci 0) 0;
  assert_equal (fibonacci 10) 55

(*
  The infix operator (>:::) fron OUnit2 (opened above) assigns a name to a list of tests and turns them into one test.
  The infix operator (>::) assigns a name to a test function.
*)
let int_tests =
  "Integer tests" >:::
  [ "Summate" >:: test_summate
  ; "LCM"     >:: test_lcm
  ; "Fib"     >:: test_fibonacci ]

let test_range _ =
  assert_equal (range 0 5) [0; 1; 2; 3; 4];
  assert_equal (range 10 10) [];
  assert_equal (range 10 12) [10; 11]

let test_arithmetic_progression _ =
  assert_equal (arithmetic_progression 1 3 4) [1; 4; 7; 10];
  assert_equal (arithmetic_progression (-10) (-10) 2) [-10; -20];
  assert_equal (arithmetic_progression 0 0 0) []

let test_factors _ =
  assert_equal (factors 10) [1; 2; 5; 10];
  assert_equal (factors 12) [1; 2; 3; 4; 6; 12];
  assert_equal (factors 0) []

let test_reverse _ =
  assert_equal (reverse [1; 2; 3; 4; 5]) [5; 4; 3; 2; 1]

let list_creation_tests =
  "List creation tests" >:::
  [ "Range"        >:: test_range
  ; "Arith. prog." >:: test_arithmetic_progression
  ; "Factors"      >:: test_factors
  ; "Reverse"      >:: test_reverse ]

let test_is_ordered _ =
  assert_equal (is_ordered ["first"; "hello"; "world"]) true;
  assert_equal (is_ordered ["second"; "hello"; "world"]) false

let test_insert_string _ =
  assert_equal (insert_string "word" ["hello"; "world"]) (Ok ["hello"; "word"; "world"]);
  assert_equal (insert_string "abc" ["world"; "hello"]) (Error "insert into unordered list")

let test_insertion_sort _ =
  assert_equal (insertion_sort ["1"; "3"; "5"; "4"; "2"]) ["1"; "2"; "3"; "4"; "5"]

let test_split_list _ =
  assert_equal (split_list [1; 2; 3; 4; 5] 3) ([1; 2; 3], [4; 5]);
  assert_equal (split_list [1; 2] 100) ([1; 2], [])

let test_merge_sort _ =
  assert_equal (merge_sort [1; 3; 5; 4; 2]) [1; 2; 3; 4; 5]

let sort_tests =
  "Sort tests" >:::
  [ "Is ordered" >:: test_is_ordered
  ; "Insert string" >:: test_insert_string
  ; "Insertion sort" >:: test_insertion_sort
  ; "Split list" >:: test_split_list
  ; "Merge sort" >:: test_merge_sort ]

let series =
  "Assignment1 Tests" >:::
  [ int_tests
  ; list_creation_tests
  ; sort_tests ]

(* The following line runs all the tests put together into `series` above *)

let () = run_test_tt_main series