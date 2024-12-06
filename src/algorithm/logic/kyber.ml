(** Baby Kyber Library Implementation *)
(* TODO : You should have a Readme.md that explains your progress so far: what is working, what is not, etc. *)

module type Kyber_Config_sig = sig
  val q : int
  val n : int
  val k : int
  val n1 : int
  val n2 : int
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
  val round : t -> t
  val binary_to_poly : bytes -> t
  val poly_to_binary : t -> bytes
  val from_coefficients : int list -> t
  val to_coefficients : t -> int list
  val to_string : t -> string
  val random : t
end

module Kyber_Config : Kyber_Config_sig = struct
  let q = 17 (* Could be 3329 *)
  let n = 4  (* Could be 256 *)
  let k = 2  (* Could be 3 or 4 *)
  let n1 = 3
  let n2 = 2
end

module Make_polynomial (C : Kyber_Config_sig) : Polynomial_t = struct
  let modulus_q = C.q
  let n = C.n
  (** Polynomial operations *)

  type t = int list
  (* Type representing a polynomial as a list of coefficients *)
  let modulus_poly = [1; 0; 0; 0; 1] (* x^4 + 1 *)
  let zero = []
  (** The zero polynomial *)

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
    try
      List.map2 ( + ) padded_p1 padded_p2
    with Invalid_argument _ ->
      failwith "Invalid padding"
  (** Add two polynomials. Make sure this handles different length polynomials as well *)

  let sub (p1 : t) (p2 : t) : t =
    let (padded_p1, padded_p2) = padding p1 p2 in
    try
      List.map2 ( - ) padded_p1 padded_p2
    with Invalid_argument _ ->
      failwith "Invalid padding"
  (** Subtract two polynomials *)

  let scalar_mul (scalar : int) (p : t) : t =
    List.map (fun coef -> scalar * coef) p
  (** Multiply a polynomial by a scalar *)

  let scalar_div (scalar : int) (p : t) : t =
    List.map (fun coef -> coef / scalar) p
  (** Divide a polynomial by a scalar *)

  (* TODO: Test this to verify *)
  let mul (p1 : t) (p2 : t) : t =
    let rec front_add p1 p2 =
      match p1, p2 with
      | [], p | p, [] -> p
      | h1 :: t1, h2 :: t2 -> (h1 + h2) :: front_add t1 t2
    in
    let rec mul_aux p1 p2 shift acc =
      match p1 with
      | [] -> acc
      | h :: t ->
          let shifted_p2 = List.init shift (fun _ -> 0) @ List.map (( * ) h) p2 in
          mul_aux t p2 (shift + 1) (front_add acc shifted_p2)
    in
    mul_aux p1 p2 0 []
  (** Multiply two polynomials *)

  (* TODO: Test this to verify *)
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
    List.map (fun coef -> coef mod modulus_q) mod_coeffs
  (** Reduce a polynomial modulo q and degree n *)

  let round (p : t) : t =
    List.map (fun coef -> if abs (coef - modulus_q) < abs coef then modulus_q else 0) p
  (** Round a polynomial's coefficients to either q/2 or 0, whichever is closer *)

  (** Convert a binary list to a polynomial. Every bit of the message is used as a coefficient *)
  let binary_to_poly (message : bytes) : t =
    
    List.init (Bytes.length message) (fun i -> if Bytes.get message i = '\x01' then 1 else 0)
  (** Convert a binary list to a polynomial *)
        
  let poly_to_binary (p : t) : bytes =
    Bytes.init (List.length p) (fun i -> if List.nth p i = 1 then '\x01' else '\x00')
  (** Convert a polynomial to a binary list *)

  let from_coefficients coeffs = coeffs
  (** Create a polynomial from a list of coefficients *)
  
  let to_coefficients p = p
  (* * Convert a polynomial to a list of coefficients *)

  let to_string p =
    List.fold_left (fun acc coef -> acc ^ (string_of_int coef) ^ " ") "" p
  (** Convert a polynomial to a string *)

  (* TODO: Create non-trivial random function, that can also give negative but small coefficients *)
  let random =
    List.init n (fun _ -> Random.int modulus_q)
  (** Generate a random polynomial of given degree *)
end

module Polynomial = Make_polynomial(Kyber_Config)

module Make_poly_mat (P : Polynomial_t) = struct
  type t = P.t list list
  let zero (rows : int) (cols : int) : t =
    List.init rows (fun _ -> List.init cols (fun _ -> P.zero))

  (* Add two polynomial matrices of equal dimensions. Assume equal dimensions *)
  let add (m1 : t) (m2 : t) : t =
    List.map2 (List.map2 P.add) m1 m2
    
  let sub (m1 : t) (_m2 : t) : t =
    m1

  let scalar_mul (scalar : int) (mat : t) : t =
    List.map (List.map (P.scalar_mul scalar)) mat

  let scalar_div (scalar : int) (mat : t) : t =
    List.map (List.map (P.scalar_div scalar)) mat

  let transpose (mat : t) : t =
    List.init (List.length (List.hd mat)) (fun i ->
      List.init (List.length mat) (fun j ->
        List.nth (List.nth mat j) i
      )
    )
  let dot_product (row : P.t list) (_col : P.t list) : P.t =
    (* Placeholder for errors *)
    List.hd row
    (* List.fold_left2 (fun acc p1 p2 -> P.add acc (P.mul p1 p2)) P.zero row col *)

  (* TODO : Verify this works *)
  let mul (m1 : t) (m2 : t) : t =
    List.init (List.length m1) (fun i ->
      List.init (List.length (List.hd m2)) (fun j ->
        dot_product (List.nth m1 i) (List.nth (transpose m2) j)
      )
    )
  
  let reduce_matrix (mat : t) : t =
    List.map (List.map P.reduce) mat

  (** Generate a random polynomial matrix of given dimensions and polynomial degree *)
  let random (rows : int) (cols : int) : t =
    List.init rows (fun _ -> List.init cols (fun _ -> P.random))

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
  
  (** Convert a PolyMat to an Polynomial list of lists *)
  let to_list (mat : t) : P.t list list =
    mat

  (** Convert a Polynomial list of lists to a PolyMat *)
  let from_list (mat : P.t list list) : t =
    mat

  let to_string (mat : t) : string =
    List.fold_left (fun acc row ->
      acc ^ (List.fold_left (fun acc' p -> acc' ^ (P.to_string p) ^ " ") "" row) ^ "\n"
    ) "" mat

end

module PolyMat = Make_poly_mat(Polynomial)

module type Kyber_t = sig
  type public_key = PolyMat.t * PolyMat.t
  type private_key = PolyMat.t
  type ciphertext = PolyMat.t * PolyMat.t

  val generate_keypair : public_key * private_key
  val encrypt : public_key -> bytes -> ciphertext
  val decrypt : private_key -> ciphertext -> bytes
end

module Make_Kyber (C : Kyber_Config_sig) (P : Polynomial_t) : Kyber_t = struct

  type public_key = PolyMat.t * PolyMat.t
  type private_key = PolyMat.t
  type ciphertext = PolyMat.t * PolyMat.t
  let q = C.q
  (* let n = C.n *)
  let k = C.k

  let generate_keypair =
    let priv_key : private_key = PolyMat.reduce_matrix (PolyMat.random 1 k) in
    let a = PolyMat.reduce_matrix (PolyMat.random k k) in
    let error = PolyMat.reduce_matrix (PolyMat.random 1 k) in
    let t = PolyMat.reduce_matrix (PolyMat.add (PolyMat.mul a priv_key) error) in
    let pub_key : public_key = (a, t) in
    (pub_key, priv_key)

  let encrypt (pub_key : public_key) (message : bytes) : ciphertext =
    let calculate_u (a : PolyMat.t) (r : PolyMat.t) (e1 : PolyMat.t) : PolyMat.t =
      PolyMat.add (PolyMat.mul (PolyMat.transpose a) r) e1
    in
    let calculate_v (t : PolyMat.t) (r : PolyMat.t) (e2 : PolyMat.t) (scaled_msg : PolyMat.t) : PolyMat.t =
      PolyMat.add (PolyMat.mul (PolyMat.transpose t) r) (PolyMat.add e2 scaled_msg)
    in
    let r = PolyMat.reduce_matrix (PolyMat.random 1 2) in
    let e1 = PolyMat.reduce_matrix (PolyMat.random 1 2) in
    let e2 = PolyMat.reduce_matrix (PolyMat.random 1 1) in
    let scaled_msg = Polynomial.scalar_mul (q / 2) (Polynomial.binary_to_poly message) in
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
    let rounded_poly = Polynomial.round noisy_poly in
    let result_poly = Polynomial.scalar_div (q / 2) rounded_poly in
    let result = Polynomial.poly_to_binary result_poly in
    result
end

module Kyber = Make_Kyber(Kyber_Config)(Polynomial)