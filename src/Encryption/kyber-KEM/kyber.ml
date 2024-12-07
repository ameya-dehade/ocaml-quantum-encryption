(** Kyber Library Implementation *)
module type Kyber_Config_sig = sig
  val q : int
  val n : int
  val k : int
  val n1 : int
  val n2 : int
end

module Kyber_Config : Kyber_Config_sig = struct
  let q = 3329
  let n = 256 
  let k = 3
  let n1 = 2
  let n2 = 2
end

module Kyber_Config_test : Kyber_Config_sig = struct
  let q = 17
  let n = 4
  let k = 2
  let n1 = 3
  let n2 = 2
end


module type Polynomial_t = sig
  type t
  val modulus_q : int
  val modulus_poly : int list
  val zero : t
  val add : t -> t -> t
  val sub : t -> t -> t
  val mul : t -> t -> t
  val scalar_mul : int -> t -> t
  val scalar_div : int -> t -> t
  val reduce : t -> t
  val add_and_reduce : t -> t -> t
  val sub_and_reduce : t -> t -> t
  val mul_and_reduce : t -> t -> t
  val round : t -> t
  val binary_to_poly : bytes -> t
  val poly_to_binary : t -> bytes
  val from_coefficients : int list -> t
  val to_coefficients : t -> int list
  val to_string : t -> string
  val random : unit -> t
  val random_small_coeff : int -> t
end

module type PolyMat_t = sig
  type t
  type poly
  val zero : int -> int -> t
  val add : t -> t -> t
  val sub : t -> t -> t
  val scalar_mul : int -> t -> t
  val scalar_div : int -> t -> t
  val transpose : t -> t
  val dot_product : poly list -> poly list -> poly
  val mul : t -> t -> t
  val random : int -> int -> t
  val random_small_coeff : int -> int -> int -> t
  val get_poly : t -> int -> int -> poly
  val set_poly : t -> int -> int -> poly -> t
  val map_poly : (poly -> poly) -> t -> t
  val reduce_matrix : t -> t
  val to_list : t -> poly list list
  val from_list : poly list list -> t
  val to_string : t -> string
  val dimensions : t -> int * int
end

module Make_polynomial (C : Kyber_Config_sig) : Polynomial_t = struct
  let modulus_q = C.q

  type t = int list (* Type representing a polynomial as a list of coefficients *)
  let modulus_poly = List.init (C.n + 1) (fun i -> if (i = 0 || i = C.n) then 1 else 0) (* x^n + 1 *)
  let zero = [] (** The zero polynomial *)

  (* Pads polynomials to make them equal length. Pad them from the front i.e add 0s to the front *)
  let padding (p1 : t) (p2 : t) : t * t =
    let len1 = List.length p1 in
    let len2 = List.length p2 in
    if len1 > len2 then
      (p1, List.init (len1 - len2) (fun _ -> 0) @ p2)
    else if len1 < len2 then
      (List.init (len2 - len1) (fun _ -> 0) @ p1, p2)
    else
      (p1, p2)

  let add (p1 : t) (p2 : t) : t =
    let (padded_p1, padded_p2) = padding p1 p2 in
    List.map2 ( + ) padded_p1 padded_p2

  let sub (p1 : t) (p2 : t) : t =
    let (padded_p1, padded_p2) = padding p1 p2 in
    List.map2 ( - ) padded_p1 padded_p2

  let scalar_mul (scalar : int) (p : t) : t =
    List.map (fun coef -> scalar * coef) p

  let scalar_div (scalar : int) (p : t) : t =
    List.map (fun coef -> coef / scalar) p

  let mul (p1 : t)(p2 : t) : t =
    let rec front_add a b = match a, b with
    | [], r | r, [] -> r
    | x::xs, y::ys -> (x + y) :: front_add xs ys
    in
    let rec mul_acc acc p q d = match p with
      | [] -> acc
      | x::xs ->
        let shifted = List.init d (fun _ -> 0) @ List.map (fun c -> x * c) q in
        mul_acc (front_add acc shifted) xs q (d + 1)
    in
    mul_acc [] p1 p2 0

  let reduce (p : t) : t =
    let rec poly_mod p m =
      let degree_p = List.length p - 1 in
      let degree_m = List.length m - 1 in
      if degree_p < degree_m then
        p
      else
        let lead_coeff = List.hd p in
        let scaled_modulus = List.map (fun coef -> coef * lead_coeff) (m @ List.init (degree_p - degree_m) (fun _ -> 0)) in
        let reduced = sub p scaled_modulus in
        poly_mod (List.tl reduced) m
    in
    let mod_coeffs = poly_mod p modulus_poly in
    List.map (fun coef -> ((coef mod modulus_q) + modulus_q) mod modulus_q) mod_coeffs

  let add_and_reduce (p1 : t) (p2 : t) : t =
    reduce (add p1 p2)

  let sub_and_reduce (p1 : t) (p2 : t) : t =
    reduce (sub p1 p2)

  let mul_and_reduce (p1 : t) (p2 : t) : t =
    reduce (mul p1 p2)

  let round (p : t) : t =
    let round_to_q_or_0 coeff =
      let q_over_2 = (modulus_q + 1) / 2 in
      let delta = q_over_2 / 2 in
      if abs (coeff - q_over_2) < delta then
        q_over_2
      else
        0
    in 
    List.map round_to_q_or_0 p

  let binary_to_poly (message : bytes) : t =
    let byte_to_bits byte =
      List.init 8 (fun i -> 
        if (int_of_char byte land (1 lsl (7 - i))) <> 0 then 1 else 0
      )
    in
    let bytes_list = List.init (Bytes.length message) (fun i -> Bytes.get message i) in
    List.flatten (List.map byte_to_bits bytes_list)

  let poly_to_binary (p : t) : bytes =
    let bits_to_byte bits =
      List.fold_left (fun acc bit -> (acc lsl 1) lor bit) 0 bits
    in
    let rec split_list n lst =
      match lst with
      | [] -> []
      | _ -> (List.filteri (fun i _ -> i < n) lst) :: (split_list n (List.filteri (fun i _ -> i >= n) lst))
    in
    let bytes_list = List.map bits_to_byte (split_list 8 p) in
    let bytes = Bytes.create (List.length bytes_list) in
    List.iteri (fun i byte -> Bytes.set bytes i (char_of_int byte)) bytes_list;
    bytes

  let from_coefficients coeffs = coeffs
  
  let to_coefficients p = p

  let to_string p =
    List.fold_left (fun acc coef -> acc ^ (string_of_int coef) ^ " ") "" p

  let random _ : t =
    List.init C.n (fun _ -> Random.int modulus_q)

  let random_small_coeff (eta : int) : t =
    List.init C.n (fun _ -> Random.int eta)
end

module Make_poly_mat (P : Polynomial_t) = struct
  type t = P.t list list
  type poly = P.t
  let zero (rows : int) (cols : int) : t =
    List.init rows (fun _ -> List.init cols (fun _ -> P.zero))

  let scalar_mul (scalar : int) (mat : t) : t =
    List.map (List.map (P.scalar_mul scalar)) mat

  let add (m1 : t) (m2 : t) : t =
    List.map2 (List.map2 P.add_and_reduce) m1 m2

  let sub (m1 : t) (m2 : t) : t =
    List.map2 (List.map2 P.sub_and_reduce) m1 m2

  let scalar_div (scalar : int) (mat : t) : t =
    List.map (List.map (P.scalar_div scalar)) mat

  let transpose (mat : t) : t =
    List.init (List.length (List.hd mat)) (fun i ->
      List.init (List.length mat) (fun j ->
        List.nth (List.nth mat j) i
      )
    )
  let dot_product (row : P.t list) (col : P.t list) : P.t =
    List.fold_left2 (fun acc p1 p2 -> P.add acc (P.mul p1 p2)) P.zero row col
    |> P.reduce

  let mul (m1 : t) (m2 : t) : t =
    List.init (List.length m1) (fun i ->
      List.init (List.length (List.hd m2)) (fun j ->
        dot_product (List.nth m1 i) (List.nth (transpose m2) j)
      )
    )
  
  let reduce_matrix (mat : t) : t =
    List.map (List.map P.reduce) mat

  let random (rows : int) (cols : int) : t =
    List.init rows (fun _ -> List.init cols (fun _ -> P.random ()))

  let random_small_coeff (rows : int) (cols : int) (eta : int): t =
    List.init rows (fun _ -> List.init cols (fun _ -> P.random_small_coeff eta))

  let get_poly (mat : t) (i : int) (j : int) : P.t =
    List.nth (List.nth mat i) j

  let set_poly (mat : t) (i : int) (j : int) (poly : P.t) : t =
    List.mapi (fun row_index row ->
      List.mapi (fun col_index p ->
        if row_index = i && col_index = j then
          poly
        else
          p
      ) row
    ) mat

  let map_poly (f : P.t -> P.t) (mat : t) : t =
    List.map (List.map f) mat
  
  let to_list (mat : t) : P.t list list =
    mat

  let from_list (mat : P.t list list) : t =
    mat

  let to_string (mat : t) : string =
    List.fold_left (fun acc row ->
      acc ^ (List.fold_left (fun acc' p -> acc' ^ (P.to_string p) ^ " ") "" row) ^ "\n"
    ) "" mat

  let dimensions (mat : t) : int * int =
    (List.length mat, List.length (List.hd mat))
end

module type Kyber_t = sig
  type poly_mat
  type public_key = poly_mat * poly_mat
  type private_key = poly_mat
  type ciphertext = poly_mat * poly_mat

  val generate_keypair : unit -> public_key * private_key
  val encrypt : public_key -> bytes -> ciphertext
  val decrypt : private_key -> ciphertext -> bytes
end

module Make_Kyber (C : Kyber_Config_sig) (P : Polynomial_t) : Kyber_t = struct
  module PolyMat = Make_poly_mat(P)
 
  type poly_mat = PolyMat.t
  type public_key = poly_mat * poly_mat
  type private_key = poly_mat
  type ciphertext = poly_mat * poly_mat
  let q = C.q
  let k = C.k
  let n1 = C.n1
  let n2 = C.n2

  let generate_keypair _ =
    let priv_key : private_key = PolyMat.random_small_coeff k 1 n1 in
    let a = PolyMat.reduce_matrix (PolyMat.random k k) in
    let error = PolyMat.reduce_matrix (PolyMat.random_small_coeff k 1 n1) in
    let t = PolyMat.reduce_matrix (PolyMat.add (PolyMat.mul a priv_key) error) in
    let pub_key : public_key = (a, t) in
    (pub_key, priv_key)

  let encrypt (pub_key : public_key) (message : bytes) : ciphertext =
    let calculate_u (a : PolyMat.t) (r : PolyMat.t) (e1 : PolyMat.t) : PolyMat.t =
      let a_transpose = PolyMat.transpose a in
      let mul_r = PolyMat.mul a_transpose r in
      let add_e1 = PolyMat.add mul_r e1 in
      add_e1
    in
    let calculate_v (t : PolyMat.t) (r : PolyMat.t) (e2 : PolyMat.t) (scaled_msg : PolyMat.t) : PolyMat.t =
      let t_transpose = PolyMat.transpose t in
      let mul_r = PolyMat.mul t_transpose r in
      let add_e2 = PolyMat.add mul_r e2 in
      let add_msg = PolyMat.add add_e2 scaled_msg in
      add_msg
    in
    let r = PolyMat.reduce_matrix (PolyMat.random_small_coeff k 1 n1) in
    let e1 = PolyMat.reduce_matrix (PolyMat.random_small_coeff k 1 n2) in
    let e2 = PolyMat.reduce_matrix (PolyMat.random_small_coeff 1 1 n2) in
    let scaled_msg = P.scalar_mul ((q + 1) / 2) (P.binary_to_poly message) in
    let zero_mat = PolyMat.zero 1 1 in
    let scaled_msg_mat = PolyMat.set_poly zero_mat 0 0 scaled_msg in
    let u = calculate_u (fst pub_key) r e1 in
    let v = calculate_v (snd pub_key) r e2 scaled_msg_mat in
    (u, v)

  let decrypt (s : private_key) (cipher : ciphertext) : bytes =
    let u = fst cipher in
    let v = snd cipher in
    let noisy_result = PolyMat.sub v (PolyMat.mul (PolyMat.transpose s) u) in
    let noisy_poly = PolyMat.get_poly noisy_result 0 0 in
    let rounded_poly = P.round noisy_poly in
    let result_poly = P.scalar_div ((q + 1) / 2) rounded_poly in
    let result = P.poly_to_binary result_poly in
    result
end