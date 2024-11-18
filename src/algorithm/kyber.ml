open Polynomial
open Ff
(* kyber.ml *)

(* ========================================================================== *)
(** {1 Parameters} *)

module Params = struct
  let n = 256
  let q = 3329
  let k = 3
  let eta1 = 3
  let eta2 = 2
  let du = 10
  let dv = 4
  let sym_bytes = 32
end

(* ========================================================================== *)
(** {1 Polynomial Operations} *)

module Poly = struct
  open Params

  module F = Ff.MakeFp(struct let prime_order = Z.of_int Params.q end)
  module PolyF = Polynomial.MakeUnivariate(F)
  type t = PolyF

  let zero = PolyF.zero
  let one = PolyF.one
  let add a b = PolyF.add a b 
  let sub a b = PolyF.sub a b 
  let mul a b = PolyF.polynomial_multiplication a b 
  let neg = failwith "Not implemented"
  let ntt = failwith "Not implemented"

  let inv_ntt = failwith "Not implemented"

  let to_bytes a = Marshal.to_bytes a []
  let of_bytes b = Marshal.from_bytes b 0

  let compress a = (* Implement compression *)
    to_bytes a (* Placeholder *)

  let decompress b = (* Implement decompression *)
    of_bytes b (* Placeholder *)
  
  let sample seed = (* Implement polynomial sampling *)
    zero (* Placeholder *)

end

(* ========================================================================== *)
(** {1 Polynomial Vector Operations} *)

module Polyvec = struct
  type t = Poly.t array

  let zero = failwith "Not implemented"
end

(* ========================================================================== *)
(** {1 Type Definitions} *)

module Types = struct
  type public_key = {
    a_matrix : polyvec;
    pk_seed : bytes;
  }
  type secret_key = {
    sk_vec : polyvec;
    sk_pk : public_key;
    sk_seed : bytes;
    z : bytes
  }
  type ciphertext = {
    u_vec : polyvec;
    v_vec : Poly.t;
  }
  type shared_secret = bytes
end

