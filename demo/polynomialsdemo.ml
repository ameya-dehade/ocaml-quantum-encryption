module F379 = Ff.MakeFp(struct let prime_order = Z.of_int 379 end);;
module Poly379 = Polynomial.MakeUnivariate(F379);;
let points =   [ (F379.of_string "2", F379.of_string "3");
    (F379.of_string "0", F379.of_string "1") ]
in
let interpolated_polynomial = Poly379.lagrange_interpolation points in
assert (
  Poly379.equal (Poly379.of_coefficients [ (F379.of_string "1", 1); (F379.of_string "1", 0) ]) interpolated_polynomial );;