open OUnit2
open Kyber

(* NOTE: All tests are conducted under the assumption modulus 17 on coefficients and modulus x^4 + 1 on polynomials *)

(* Polynomial Module Tests *)
let test_polynomial_zero _ =
  let zero = Polynomial.zero in
  assert_equal [] (Polynomial.to_coefficients zero)

let test_polynomial_add_same_length _ =
  let p1 = Polynomial.from_coefficients [1; 2; 3] in
  let p2 = Polynomial.from_coefficients [4; 5; 6] in
  let result = Polynomial.add p1 p2 in
  assert_equal [5; 7; 9] (Polynomial.to_coefficients result)

let test_polynomial_add_different_length _ =
  let p1 = Polynomial.from_coefficients [1; 2; 3] in
  let p2 = Polynomial.from_coefficients [4; 5] in
  let result = Polynomial.add p1 p2 in
  assert_equal [1; 6; 8] (Polynomial.to_coefficients result)

let test_polynomial_sub_same_length _ =
  let p1 = Polynomial.from_coefficients [4; 5; 6] in
  let p2 = Polynomial.from_coefficients [1; 2; 3] in
  let result = Polynomial.sub p1 p2 in
  assert_equal [3; 3; 3] (Polynomial.to_coefficients result)

let test_polynomial_sub_different_length _ =
  let p1 = Polynomial.from_coefficients [4; 5; 6] in
  let p2 = Polynomial.from_coefficients [1; 2] in
  let result = Polynomial.sub p1 p2 in
  assert_equal [4; 4; 4] (Polynomial.to_coefficients result)

let test_polynomial_scalar_mul _ =
  let p = Polynomial.from_coefficients [1; 2; 3] in
  let result = Polynomial.scalar_mul 3 p in
  assert_equal [3; 6; 9] (Polynomial.to_coefficients result)

let test_polynomial_reduce _ =
  let p = Polynomial.from_coefficients [5; 0; 0; 0; 4; 0; 2; 89] in
  let result = Polynomial.reduce p in
  assert_equal [16; 0; 2; 4] (Polynomial.to_coefficients result)

let test_polynomial_mul_simple _ =
  let p1 = Polynomial.from_coefficients [1; 1] in
  let p2 = Polynomial.from_coefficients [1; 1] in
  let result = Polynomial.mul_and_reduce p1 p2 in
  assert_equal [1; 2; 1] (Polynomial.to_coefficients result)

let test_polynomial_mul_complex _ =
  let p1 = Polynomial.from_coefficients [1; 0; 4; 21] in
  let p2 = Polynomial.from_coefficients [3; 1; 2] in
  let result = Polynomial.mul_and_reduce p1 p2 in
  assert_equal [14; 16; 9; 7] (Polynomial.to_coefficients result)

let test_polynomial_mul_complex_2 _ =
  let p1 = Polynomial.from_coefficients [1; 2; 45] in
  let p2 = Polynomial.from_coefficients [1; 0; 0; 7; 0; 0; 1] in
  let result = Polynomial.mul_and_reduce p1 p2 in
  assert_equal [7; 7; 12; 15] (Polynomial.to_coefficients result)

(* PolyMat Module Tests *)

let test_polymat_zero _ =
  let zero_mat = PolyMat.zero 2 2 in
  assert_equal [] (PolyMat.get_poly zero_mat 0 0 |> Polynomial.to_coefficients)

(* Detailed test that checks the result matrix with expected matrix*)
let test_polymat_add _ =
  (* Create two 2x2 matrices with known polynomials *)
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 2]; Polynomial.from_coefficients [3; 4]];
    [Polynomial.from_coefficients [5; 6]; Polynomial.from_coefficients [7; 8]]
  ] in
  let m2 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 1]; Polynomial.from_coefficients [2; 2]];
    [Polynomial.from_coefficients [3; 3]; Polynomial.from_coefficients [4; 4]]
  ] in
  
  let expected = PolyMat.from_list [
    [Polynomial.from_coefficients [2; 3]; Polynomial.from_coefficients [5; 6]];
    [Polynomial.from_coefficients [8; 9]; Polynomial.from_coefficients [11; 12]]
  ] in
  
  let result = PolyMat.add m1 m2 in
  assert_equal expected result

(* Detailed test that checks the result matrix with expected matrix*)
let test_polymat_sub _ =
  (* Create two 2x2 matrices with known polynomials *)
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 2]; Polynomial.from_coefficients [3; 4]];
    [Polynomial.from_coefficients [5; 6]; Polynomial.from_coefficients [7; 8]]
  ] in
  let m2 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 1]; Polynomial.from_coefficients [2; 2]];
    [Polynomial.from_coefficients [3; 3]; Polynomial.from_coefficients [4; 4]]
  ] in
  
  (* Expected result after subtraction *)
  let expected = [
    [Polynomial.from_coefficients [0; 1]; Polynomial.from_coefficients [1; 2]];
    [Polynomial.from_coefficients [2; 3]; Polynomial.from_coefficients [3; 4]]
  ] in
  
  (* Perform matrix subtraction *)
  let result = PolyMat.sub m1 m2 in
  assert_equal expected (PolyMat.to_list result)

let test_polymat_scalar_mul _ =
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 2]; Polynomial.from_coefficients [3; 4]];
    [Polynomial.from_coefficients [5; 6]; Polynomial.from_coefficients [7; 8]]
  ] in
  let scalar = 2 in
  let expected = [
    [Polynomial.from_coefficients [2; 4]; Polynomial.from_coefficients [6; 8]];
    [Polynomial.from_coefficients [10; 12]; Polynomial.from_coefficients [14; 16]]
  ] in
  let result = PolyMat.scalar_mul scalar m1 in
  assert_equal expected (PolyMat.to_list result)

let test_polymat_mul_trivial_singleton _= 
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 0; 4; 21]]
  ] in
  let m2 = PolyMat.from_list [
    [Polynomial.from_coefficients [3; 1; 2]]
  ] in
  let expected = [
    [Polynomial.from_coefficients [14; 16; 9; 7]]
  ] in
  let result = PolyMat.mul m1 m2 in
  assert_equal expected (PolyMat.to_list result)

(* Detailed test that checks the result matrix with expected matrix*)

let test_polymat_mul_square_and_singleline_matrix _ = 
  (* Create a 2x2 matrix and a 1x2 matrix with known polynomials *)
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [6; 16; 16; 11]; Polynomial.from_coefficients [9; 4; 6; 3]];
    [Polynomial.from_coefficients [5; 3; 10; 1]; Polynomial.from_coefficients [6; 1; 9; 15]]
  ] in
  let m2 = PolyMat.from_list [
    [Polynomial.from_coefficients [-1; -1; 1; 0]];
    [Polynomial.from_coefficients [-1; 0; -1; 0]]
  ] in
  let expected = [
    [Polynomial.from_coefficients [16; 14; 0; 7]];
    [Polynomial.from_coefficients [10; 11; 12; 6]]
  ] in
  let result = PolyMat.mul m1 m2 in
  assert_equal expected (PolyMat.to_list result)

(* Detailed test that checks the result matrix with expected matrix. Remember that multiplication performs modulus on both the coefficient and polynomial*)
let test_polymat_mul_square_matrix _ =
  (* Create two 2x2 matrices with known polynomials *)
  let m1 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 2]; Polynomial.from_coefficients [3; 4]];
    [Polynomial.from_coefficients [5; 6]; Polynomial.from_coefficients [7; 8]]
  ] in
  let m2 = PolyMat.from_list [
    [Polynomial.from_coefficients [1; 1]; Polynomial.from_coefficients [2; 2]];
    [Polynomial.from_coefficients [3; 3]; Polynomial.from_coefficients [4; 4]]
  ] in
  
  (* Expected result after multiplication *)
  let expected = [
    [Polynomial.from_coefficients [10; 7; 14]; Polynomial.from_coefficients [14; 0; 3]];
    [Polynomial.from_coefficients [9; 5; 13]; Polynomial.from_coefficients [4; 14; 10]]
  ] in
  
  (* Perform matrix multiplication *)
  let result = PolyMat.mul m1 m2 in
  assert_equal expected (PolyMat.to_list result)

let polynomial_suite =
  "polynomial_test_suite" >::: [
    "test_polynomial_zero" >:: test_polynomial_zero;
    "test_polynomial_add_same_length" >:: test_polynomial_add_same_length;
    "test_polynomial_add_different_length" >:: test_polynomial_add_different_length;
    "test_polynomial_sub_same_length" >:: test_polynomial_sub_same_length;
    "test_polynomial_sub_different_length" >:: test_polynomial_sub_different_length;
    "test_polynomial_scalar_mul" >:: test_polynomial_scalar_mul;
    "test_polynomial_reduce" >:: test_polynomial_reduce;
    "test_polynomial_mul_simple" >:: test_polynomial_mul_simple;
    "test_polynomial_mul_complex" >:: test_polynomial_mul_complex;
    "test_polynomial_mul_complex_2" >:: test_polynomial_mul_complex_2;
  ]

let polymat_suite = 
  "polymat_test_suite" >::: [
    "test_polymat_zero" >:: test_polymat_zero;
    "test_polymat_add" >:: test_polymat_add;
    "test_polymat_sub" >:: test_polymat_sub;
    "test_polymat_scalar_mul" >:: test_polymat_scalar_mul;
    "test_polymat_mul_trivial_singleton" >:: test_polymat_mul_trivial_singleton;
    "test_polymat_mul_square_and_singleline_matrix" >:: test_polymat_mul_square_and_singleline_matrix;
    "test_polymat_mul_square_matrix" >:: test_polymat_mul_square_matrix;
  ]