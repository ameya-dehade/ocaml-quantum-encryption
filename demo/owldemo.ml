(* demo.ml *)
open Owl


let () =
 (* Matrix Operations *)
 Printf.printf "Matrix Operations:\n";
  (* Create two 2x2 matrices *)
 let a = Mat.of_array [|1.0; 2.0; 3.0; 4.0|] 2 2 in
 let b = Mat.of_array [|4.0; 3.0; 2.0; 1.0|] 2 2 in
  (* Matrix addition *)
 let c = Mat.add a b in
 Printf.printf "Matrix A:\n"; Mat.print a;
 Printf.printf "Matrix B:\n"; Mat.print b;
 Printf.printf "A + B:\n"; Mat.print c;
  (* Matrix multiplication *)
 let d = Mat.dot a b in
 Printf.printf "A * B (dot product):\n"; Mat.print d;


 (* Statistics *)
 Printf.printf "\nStatistics:\n";
  (* Generate random data *)
 let data = Mat.uniform 1 10 in
 Printf.printf "Data:\n"; Mat.print data;
  (* Calculate and print mean, variance, and standard deviation *)
 let mean = Stats.mean (Mat.to_array data) in
 let variance = Stats.var (Mat.to_array data) in
 let std_dev = Stats.std (Mat.to_array data) in
  Printf.printf "Mean: %f\n" mean;
 Printf.printf "Variance: %f\n" variance;
 Printf.printf "Standard Deviation: %f\n" std_dev;


 (* Linear Algebra *)
 Printf.printf "\nLinear Algebra:\n";
  (* Define matrix A and vector b *)
 let a = Mat.of_array [|3.0; 2.0; 1.0; 1.0|] 2 2 in
 let b = Mat.of_array [|5.0; 5.0|] 2 1 in
 Printf.printf "Matrix A:\n"; Mat.print a;
 Printf.printf "Vector b:\n"; Mat.print b;
  (* Solve the linear system Ax = b *)
 let x = Linalg.D.linsolve a b in
 Printf.printf "Solution x:\n"; Mat.print x;




