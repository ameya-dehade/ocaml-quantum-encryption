(* Define two arbitrary precision integers *)
let a = Z.of_string "123456789123456789123456789123456789123456789123456789"
let b = Z.of_string "987654321987654321987654321987654321987654321987654321"

(* Perform operations *)
let sum = Z.add a b
let product = Z.mul a b
let quotient, remainder = Z.div_rem a b

(* Convert results to strings for printing *)
let () =
  Printf.printf "a = %s\n" (Z.to_string a);
  Printf.printf "b = %s\n" (Z.to_string b);
  Printf.printf "sum = %s\n" (Z.to_string sum);
  Printf.printf "product = %s\n" (Z.to_string product);
  Printf.printf "quotient = %s, remainder = %s\n"
    (Z.to_string quotient) (Z.to_string remainder)