(** Kyber Library Implementation *)
open Core

module type Kyber_Config_sig = sig
  val q : int
  val n : int
  val k : int
  val n1 : int
  val n2 : int
end

module Kyber512_Config : Kyber_Config_sig = struct
  let q = 3329
  let n = 256 
  let k = 2
  let n1 = 3
  let n2 = 2
end

module Kyber768_Config : Kyber_Config_sig = struct
  let q = 3329
  let n = 256 
  let k = 3
  let n1 = 2
  let n2 = 2
end

module Kyber1024_Config : Kyber_Config_sig = struct
  let q = 3329
  let n = 256 
  let k = 4
  let n1 = 2
  let n2 = 2
end

module Test_Kyber_Config_Mini : Kyber_Config_sig = struct
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
  val from_string : string -> t
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
  val from_string : string -> t
  val dimensions : t -> int * int
end

module Make_polynomial (C : Kyber_Config_sig) : Polynomial_t = struct
  let modulus_q = C.q

  type t = int list (* Type representing a polynomial as a list of coefficients *)
  let modulus_poly = List.init ~f:(fun i -> if (i = 0 || i = C.n) then 1 else 0) (C.n + 1) (* x^n + 1 *)
  let zero = [] (** The zero polynomial *)

  (* Pads polynomials to make them equal length. Pad them from the front i.e add 0s to the front *)
  let padding (p1 : t) (p2 : t) : t * t =
    let len1 = List.length p1 in
    let len2 = List.length p2 in
    if len1 > len2 then
      (p1, List.init ~f:(fun _ -> 0) (len1 - len2) @ p2)
    else if len1 < len2 then
      (List.init ~f:(fun _ -> 0) (len2 - len1) @ p1, p2)
    else
      (p1, p2)

  let add (p1 : t) (p2 : t) : t =
    let (padded_p1, padded_p2) = padding p1 p2 in
    List.map2_exn ~f:(fun x y -> x + y) padded_p1 padded_p2

  let sub (p1 : t) (p2 : t) : t =
    let (padded_p1, padded_p2) = padding p1 p2 in
    List.map2_exn ~f:(fun x y -> x - y) padded_p1 padded_p2

  let scalar_mul (scalar : int) (p : t) : t =
    List.map ~f:(fun coef -> scalar * coef) p

  let scalar_div (scalar : int) (p : t) : t =
    List.map ~f:(fun coef -> coef / scalar) p

  let mul (p1 : t)(p2 : t) : t =
    let rec front_add a b = match a, b with
    | [], r | r, [] -> r
    | x::xs, y::ys -> (x + y) :: front_add xs ys
    in
    let rec mul_acc acc p q d = match p with
      | [] -> acc
      | x::xs ->
        let shifted = List.init d ~f:(fun _ -> 0) @ List.map ~f:(fun c -> x * c) q in
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
        let lead_coeff = List.hd_exn p in
        let scaled_modulus = List.map ~f:(fun coef -> coef * lead_coeff) (m @ List.init (degree_p - degree_m) ~f:(fun _ -> 0)) in
        let reduced = sub p scaled_modulus in
        poly_mod (List.tl_exn reduced) m
    in
    let mod_coeffs = poly_mod p modulus_poly in
    List.map ~f:(fun coef -> ((coef mod modulus_q) + modulus_q) mod modulus_q) mod_coeffs

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
    List.map ~f:round_to_q_or_0 p

  let binary_to_poly (message : bytes) : t =
    let byte_to_bits byte =
      List.init 8 ~f:(fun i -> 
        if (int_of_char byte land (1 lsl (7 - i))) <> 0 then 1 else 0
      )
    in
    let bytes_list = List.init (Bytes.length message) ~f:(fun i -> Bytes.get message i) in
    List.concat (List.map ~f:byte_to_bits bytes_list)

  let poly_to_binary (p : t) : bytes =
    let bits_to_byte bits =
      List.fold_left ~f:(fun acc bit -> (acc lsl 1) lor bit) ~init:0 bits
    in
    let rec split_list n lst =
      match lst with
      | [] -> []
      | _ -> (List.filteri ~f:(fun i _ -> i < n) lst) :: (split_list n (List.filteri ~f:(fun i _ -> i >= n) lst))
    in
    let bytes_list = List.map ~f:bits_to_byte (split_list 8 p) in
    let bytes = Bytes.create (List.length bytes_list) in
    List.iteri ~f:(fun i byte -> Bytes.set bytes i (char_of_int byte)) bytes_list;
    bytes

  let from_coefficients coeffs = coeffs
  
  let to_coefficients p = p

  let to_string p =
    String.concat ~sep:" " (List.map ~f:string_of_int p)
  
  let from_string s =
    s 
    |> String.split_on_chars ~on:[' ']
    |> List.map ~f:int_of_string

  let random _ : t =
    List.init C.n ~f:(fun _ -> Random.int modulus_q)

  let random_small_coeff (eta : int) : t =
    let random_bit () = Random.int 2 in
    let cbd_sample eta =
      let rec sample eta acc =
        if eta = 0 then acc
        else
          let a = random_bit () in
          let b = random_bit () in
          sample (eta - 1) (acc + a - b)
      in
      sample eta 0
    in
    let rec generate n acc =
      if n < 0 then acc
      else generate (n - 1) (cbd_sample eta :: acc)
    in
    generate C.n []
end

module Make_poly_mat (P : Polynomial_t) = struct
  type t = P.t list list
  type poly = P.t
  let zero (rows : int) (cols : int) : t =
    List.init rows ~f:(fun _ -> List.init cols ~f:(fun _ -> P.zero))

  let scalar_mul (scalar : int) (mat : t) : t =
    List.map ~f:(List.map ~f:(P.scalar_mul scalar)) mat

  let add (m1 : t) (m2 : t) : t =
    List.map2_exn ~f:(List.map2_exn ~f:P.add_and_reduce) m1 m2

  let sub (m1 : t) (m2 : t) : t =
    List.map2_exn ~f:(List.map2_exn ~f:P.sub_and_reduce) m1 m2

  let scalar_div (scalar : int) (mat : t) : t =
    List.map ~f:(List.map ~f:(P.scalar_div scalar)) mat

  let transpose (mat : t) : t =
    List.init (List.length (List.hd_exn mat)) ~f:(fun i ->
      List.init (List.length mat) ~f:(fun j ->
        List.nth_exn (List.nth_exn mat j) i
      )
    )
  let dot_product (row : P.t list) (col : P.t list) : P.t =
    List.fold2_exn ~f:(fun acc p1 p2 -> P.add acc (P.mul p1 p2)) ~init:P.zero row col
    |> P.reduce

  let mul (m1 : t) (m2 : t) : t =
    List.init (List.length m1)~f:(fun i ->
      List.init (List.length (List.hd_exn m2)) ~f:(fun j ->
        dot_product (List.nth_exn m1 i) (List.nth_exn (transpose m2) j)
      )
    )
  
  let reduce_matrix (mat : t) : t =
    List.map ~f:(List.map ~f:P.reduce) mat

  let random (rows : int) (cols : int) : t =
    List.init rows ~f:(fun _ -> List.init cols ~f:(fun _ -> P.random ()))

  let random_small_coeff (rows : int) (cols : int) (eta : int): t =
    List.init rows ~f:(fun _ -> List.init cols ~f:(fun _ -> P.random_small_coeff eta))

  let get_poly (mat : t) (i : int) (j : int) : P.t =
    List.nth_exn (List.nth_exn mat i) j

  let set_poly (mat : t) (i : int) (j : int) (poly : P.t) : t =
    List.mapi ~f:(fun row_index row ->
      List.mapi ~f:(fun col_index p ->
        if row_index = i && col_index = j then
          poly
        else
          p
      ) row
    ) mat

  let map_poly (f : P.t -> P.t) (mat : t) : t =
    List.map ~f:(List.map ~f) mat
  
  let to_list (mat : t) : P.t list list =
    mat

  let from_list (mat : P.t list list) : t =
    mat

  let dimensions (mat : t) : int * int =
    (List.length mat, List.length (List.hd_exn mat))

  let to_string (mat : t) : string =
    match mat with
  | [] -> ""
  | rows -> 
      rows 
      |> List.map ~f:(fun row -> 
          row 
          |> List.map ~f:P.to_coefficients
          |> List.map ~f:(fun coeffs -> String.concat ~sep:" " (List.map ~f:string_of_int coeffs))
          |> String.concat ~sep:",")
      |> String.concat ~sep:"\n"

  let from_string (s : string) : t =
    if String.equal s "" then []
    else
      s 
      |> String.split_on_chars ~on:['\n']
      |> List.map ~f:(fun row -> 
          row 
          |> String.split_on_chars ~on:[',']
          |> List.map ~f:(fun coeffs -> 
              coeffs 
              |> String.split_on_chars ~on:[' ']
              |> List.map ~f:int_of_string
              |> P.from_coefficients
            )
        )

end

module type Kyber_t = sig
  type poly_mat
  type public_key = poly_mat * poly_mat
  type private_key = poly_mat
  type ciphertext = poly_mat * poly_mat

  val public_key_to_string : public_key -> string
  val private_key_to_string : private_key -> string
  val ciphertext_to_string : ciphertext -> string
  val public_key_from_string : string -> public_key
  val private_key_from_string : string -> private_key
  val ciphertext_from_string : string -> ciphertext
  val generate_keypair : unit -> string * string
  val encrypt : string -> bytes -> string
  val decrypt : string -> string -> bytes
end

module Make_Kyber (C : Kyber_Config_sig) : Kyber_t = struct
  module Polynomial = Make_polynomial(C)
  module PolyMat = Make_poly_mat(Polynomial)

  type poly_mat = PolyMat.t
  type public_key = poly_mat * poly_mat
  type private_key = poly_mat
  type ciphertext = poly_mat * poly_mat
  let q = C.q
  let k = C.k
  let n1 = C.n1
  let n2 = C.n2

  let public_key_to_string (pub_key : public_key) : string =
    let a = PolyMat.to_string (fst pub_key) in
    let t = PolyMat.to_string (snd pub_key) in
    a ^ "|" ^ t
  
  let private_key_to_string (priv_key : private_key) : string =
    PolyMat.to_string priv_key

  let ciphertext_to_string (cipher : ciphertext) : string =
    let u = PolyMat.to_string (fst cipher) in
    let v = PolyMat.to_string (snd cipher) in
    u ^ "|" ^ v
  
  let public_key_from_string (s : string) : public_key =
    let split = String.split_on_chars ~on:['|'] s in
    let a = PolyMat.from_string (List.nth_exn split 0) in
    let t = PolyMat.from_string (List.nth_exn split 1) in
    (a, t)

  let private_key_from_string (s : string) : private_key =
    PolyMat.from_string s
  
  let ciphertext_from_string (s : string) : ciphertext =
    let split = String.split_on_chars ~on:['|'] s in
    let u = PolyMat.from_string (List.nth_exn split 0) in
    let v = PolyMat.from_string (List.nth_exn split 1) in
    (u, v)

  let generate_keypair _ =
    let priv_key : private_key = PolyMat.random_small_coeff k 1 n1 in
    let a = PolyMat.reduce_matrix (PolyMat.random k k) in
    let error = PolyMat.reduce_matrix (PolyMat.random_small_coeff k 1 n1) in
    let t = PolyMat.reduce_matrix (PolyMat.add (PolyMat.mul a priv_key) error) in
    let pub_key : public_key = (a, t) in
    let x = (public_key_to_string pub_key, private_key_to_string priv_key) in
    x

  let encrypt (pub_key : string) (message : bytes) : string =
    let pub_key = public_key_from_string pub_key in
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
    let scaled_msg = Polynomial.scalar_mul ((q + 1) / 2) (Polynomial.binary_to_poly message) in
    let zero_mat = PolyMat.zero 1 1 in
    let scaled_msg_mat = PolyMat.set_poly zero_mat 0 0 scaled_msg in
    let u = calculate_u (fst pub_key) r e1 in
    let v = calculate_v (snd pub_key) r e2 scaled_msg_mat in
    let x = ciphertext_to_string (u, v) in
    x

  let decrypt (s : string) (cipher : string) : bytes =
    let s = private_key_from_string s in
    let cipher = ciphertext_from_string cipher in
    let u = fst cipher in
    let v = snd cipher in
    let noisy_result = PolyMat.sub v (PolyMat.mul (PolyMat.transpose s) u) in
    let noisy_poly = PolyMat.get_poly noisy_result 0 0 in
    let rounded_poly = Polynomial.round noisy_poly in
    let result_poly = Polynomial.scalar_div ((q + 1) / 2) rounded_poly in
    let result = Polynomial.poly_to_binary result_poly in
    result
  
end