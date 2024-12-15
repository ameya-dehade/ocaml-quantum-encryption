@ocaml.doc(" Kyber Library Implementation ")
module type Kyber_Config_sig = {
  let q: int
  let n: int
  let k: int
  let n1: int
  let n2: int
}

module Kyber512_Config: Kyber_Config_sig = {
  let q = 3329
  let n = 256
  let k = 2
  let n1 = 3
  let n2 = 2
}

module Kyber768_Config: Kyber_Config_sig = {
  let q = 3329
  let n = 256
  let k = 3
  let n1 = 2
  let n2 = 2
}

module Kyber1024_Config: Kyber_Config_sig = {
  let q = 3329
  let n = 256
  let k = 4
  let n1 = 2
  let n2 = 2
}

module Test_Kyber_Config_Mini: Kyber_Config_sig = {
  let q = 17
  let n = 4
  let k = 2
  let n1 = 3
  let n2 = 2
}

module type Polynomial_t = {
  type t
  let modulus_q: int
  let modulus_poly: t
  let zero: t
  let add: (t, t) => t
  let sub: (t, t) => t
  let mul: (t, t) => t
  let scalar_mul: (int, t) => t
  let scalar_div: (int, t) => t
  let reduce: t => t
  let add_and_reduce: (t, t) => t
  let sub_and_reduce: (t, t) => t
  let mul_and_reduce: (t, t) => t
  let round: t => t
  let binary_to_poly: bytes => t
  let poly_to_binary: t => bytes
  let from_coefficients: list<int> => t
  let to_coefficients: t => list<int>
  let to_string: t => string
  let from_string: string => t
  let random: unit => t
  let random_small_coeff: int => t
}

module type PolyMat_t = {
  type t
  type poly
  let zero: (int, int) => t
  let add: (t, t) => t
  let sub: (t, t) => t
  let scalar_mul: (int, t) => t
  let scalar_div: (int, t) => t
  let transpose: t => t
  let dot_product: (list<poly>, list<poly>) => poly
  let mul: (t, t) => t
  let random: (int, int) => t
  let random_small_coeff: (int, int, int) => t
  let get_poly: (t, int, int) => poly
  let set_poly: (t, int, int, poly) => t
  let map_poly: (poly => poly, t) => t
  let reduce_matrix: t => t
  let to_list: t => list<list<poly>>
  let from_list: list<list<poly>> => t
  let to_string: t => string
  let from_string: string => t
  let dimensions: t => (int, int)
}

module Make_polynomial = (C: Kyber_Config_sig): Polynomial_t => {
  Random.self_init()

  let modulus_q = C.q

  type t = list<int> /* Type representing a polynomial as a list of coefficients */
  let modulus_poly = List.fromInitializer(~length=(C.n + 1), i =>
    if i == 0 || i == C.n {
      1
    } else {
      0
    }) /* x^n + 1 */
  @ocaml.doc(" The zero polynomial ")
  let zero = list{}

  /* Pads polynomials to make them equal length. Pad them from the front i.e add 0s to the front */
  let padding = (p1: t, p2: t): (t, t) => {
    let len1 = List.length(p1)
    let len2 = List.length(p2)
    if len1 > len2 {
      (p1, List.concat(List.make(~length=len1 - len2, 0), p2))
    } else if len1 < len2 {
      (List.concat(List.make(~length=len2 - len1, 0), p1), p2)
    } else {
      (p1, p2)
    }
  }

  let add = (p1: t, p2: t): t => {
    let (padded_p1, padded_p2) = padding(p1, p2)
    List.zipBy(padded_p1, padded_p2, (x, y) => x + y)
  }

  let sub = (p1: t, p2: t): t => {
    let (padded_p1, padded_p2) = padding(p1, p2)
    List.zipBy(padded_p1, padded_p2, (x, y) => x - y) 
  }

  let scalar_mul = (scalar: int, p: t): t => List.map(p, coef => scalar * coef)

  let scalar_div = (scalar: int, p: t): t => List.map(p, coef => coef / scalar)

  let mul = (p1: t, p2: t): t => {
    let rec front_add = (a, b) =>
      switch (a, b) {
      | (list{}, r) | (r, list{}) => r
      | (list{x, ...xs}, list{y, ...ys}) => list{x + y, ...front_add(xs, ys)}
      }

    let rec mul_acc = (acc, p, q, d) =>
      switch p {
      | list{} => acc
      | list{x, ...xs} =>
        let shifted = List.concat(
        List.make(~length=d, 0),
        List.map(q, c => x * c)
      )
        mul_acc(front_add(acc, shifted), xs, q, d + 1)
      }

    mul_acc(list{}, p1, p2, 0)
  }

  let reduce = (p: t) : t => {
    let rec poly_mod = (p : t, m : t) => {
      let degree_p = List.length(p) - 1
      let degree_m = List.length(m) - 1
      if degree_p < degree_m {
        p
      } else {
        let lead_coeff = List.headExn(p)
        let scaled_modulus = List.map(
          List.concat(m, List.make(~length=degree_p - degree_m, 0)),
          coef => coef * lead_coeff
        )
        let reduced = sub(p, scaled_modulus)
        poly_mod(List.tailExn(reduced), m)
      }
    }

    let mod_coeffs = poly_mod(p, modulus_poly)
    List.map(mod_coeffs, coef => Int.mod(Int.mod(coef, modulus_q) + modulus_q, modulus_q))
  }

  let add_and_reduce = (p1: t, p2: t): t => reduce(add(p1, p2))

  let sub_and_reduce = (p1: t, p2: t): t => reduce(sub(p1, p2))

  let mul_and_reduce = (p1: t, p2: t): t => reduce(mul(p1, p2))

  let round = (p: t): t => {
    let round_to_q_or_0 = coeff => {
      let q_over_2 = (modulus_q + 1) / 2
      let delta = q_over_2 / 2
      if abs(coeff - q_over_2) < delta {
        q_over_2
      } else {
        0
      }
    }

    List.map(p, round_to_q_or_0)
  }

  let binary_to_poly = (message: bytes): t => {
    let byte_to_bits = (byte : char) =>
      List.fromInitializer(~length=8, i =>
        if land(int_of_char(byte), lsl(1, 7 - i)) != 0 {
          1
        } else {
          0
        }
      )

    let bytes_list = List.fromInitializer(~length=Bytes.length(message), i => Bytes.get(message, i))
    bytes_list
    -> List.map(byte_to_bits)
    -> Belt.List.flatten
  }


let poly_to_binary = (poly: t): bytes => {
  // Group bits into chunks of 8
  let bits_to_byte = (bits: list<int>): char => {
    List.reduceWithIndex(bits, 0, (acc, bit, i) =>
      if bit == 1 {
        acc + lsl(1, 7 - i)
      } else {
        acc
      }
    )->char_of_int
  }

  // Pad list length to multiple of 8 if needed
  let padded_bits = {
    let remainder = mod(List.length(poly), 8)
    if remainder == 0 {
      poly
    } else {
      List.concat(poly, List.make(~length=8 - remainder, 0))
    }
  }

  // Group into chunks of 8 bits and convert each to byte
  let num_bytes = List.length(padded_bits) / 8
  let bytes = Bytes.create(num_bytes)

  let rec chunk_func = (list, size) => {
    if List.length(list) <= size {
      [list]
    } else {
      switch List.splitAt(list, size) {
      | Some((head, tail)) => [head, ...chunk_func(tail, size)]
      | None => []
      }
    }
  }
  
  let chunks = chunk_func(padded_bits, 8)
  let chunks_list = Belt.List.fromArray(chunks)
  List.forEachWithIndex(chunks_list, (chunk, i) => {
    Bytes.set(bytes, i, bits_to_byte(chunk))
  })

  bytes
}

  let from_coefficients = coeffs => coeffs

  let to_coefficients = p => p

  let to_string = p => {
    p
    ->List.map(x => x->Int.toString)
    ->List.toArray
    ->Array.join(" ")    
  }

  let from_string = s =>
    s
    ->String.split(" ")
    // ->Belt.Array.keep(str => str != "")
    ->Belt.Array.map(str => switch Int.fromString(str) {
      | Some(n) => n
      | None => -9999
      }
    )->Belt.List.fromArray


  let random = (_): t => List.fromInitializer(~length=C.n, _ => Random.int(modulus_q))

  let random_small_coeff = (eta: int): t => {
    let random_bit = () => Random.int(2)
    let cbd_sample = eta => {
      let rec sample = (eta, acc) =>
        if eta == 0 {
          acc
        } else {
          let a = random_bit()
          let b = random_bit()
          sample(eta - 1, acc + a - b)
        }

      sample(eta, 0)
    }

    let rec generate = (n, acc) =>
      if n < 0 {
        acc
      } else {
        generate(n - 1, list{cbd_sample(eta), ...acc})
      }

    generate(C.n, list{})
  }
}

module Make_poly_mat = (P: Polynomial_t) => {
  type t = list<list<P.t>>
  type poly = P.t
  let zero = (rows: int, cols: int): t => List.make(~length=rows, List.make(~length=cols, P.zero))

  let scalar_mul = (scalar: int, mat: t): t => 
    List.map(mat, row => List.map(row, poly => P.scalar_mul(scalar, poly)))

  let add = (m1: t, m2: t): t => 
    List.zipBy(m1, m2, (row1, row2) => 
      List.zipBy(row1, row2, P.add_and_reduce)
    )

  let sub = (m1: t, m2: t): t => 
    List.zipBy(m1, m2, (row1, row2) =>
      List.zipBy(row1, row2, P.sub_and_reduce)
    )

  let scalar_div = (scalar: int, mat: t): t => 
      List.map(mat, row => List.map(row, poly => P.scalar_div(scalar, poly)))

  let transpose = (mat: t): t =>
    List.fromInitializer(~length=List.length(List.headExn(mat)), i =>
      List.fromInitializer(~length=List.length(mat), j => List.getExn(List.getExn(mat, j), i))
    )
    
  let dot_product = (row: list<P.t>, col: list<P.t>): P.t =>
    List.reduce2(
        row,
        col,
        P.zero,
        (acc, p1, p2) => P.add(acc, P.mul(p1, p2))
      ) -> P.reduce

  let mul = (m1: t, m2: t): t =>
    List.fromInitializer(~length=List.length(m1), i =>
      List.fromInitializer(~length=List.length(List.headExn(m2)), j =>
        dot_product(List.getExn(m1, i), List.getExn(transpose(m2), j))
      )
    )

  let reduce_matrix = (mat: t): t => 
    List.map(mat, row => List.map(row, poly => P.reduce(poly)))

  let random = (rows: int, cols: int): t =>
    List.make(~length=rows, List.make(~length=cols, P.random()))

  let random_small_coeff = (rows: int, cols: int, eta: int): t =>
    List.make(~length=rows, List.make(~length=cols, P.random_small_coeff(eta)))

  let get_poly = (mat: t, i: int, j: int): P.t => 
    List.getExn(List.getExn(mat, i), j)

  let set_poly = (mat: t, i: int, j: int, poly: P.t): t =>
    List.mapWithIndex(mat, (row, row_index) => 
      List.mapWithIndex(row, (p, col_index) =>
        if row_index == i && col_index == j {
          poly
        } else {
          p
        })
    )

  let map_poly = (f: P.t => P.t, mat: t): t => 
    List.map(mat, row => List.map(row, poly => f(poly)))

  let to_list = (mat: t): list<list<P.t>> => mat

  let from_list = (mat: list<list<P.t>>): t => mat

  let dimensions = (mat: t): (int, int) => (List.length(mat), List.length(List.headExn(mat)))

  let to_string = (mat: t): string => {
    switch mat {
    | list{} => ""
    | rows =>
        rows
        ->List.map(row =>
          row
          ->List.map(P.to_string)
          ->Belt.List.toArray
          ->Array.join(",")
        )
        ->Belt.List.toArray
        ->Array.join("\n")
    }
  }

  let from_string = (s: string): t =>{
    let rows = String.split(s, "\n")->List.fromArray
    let mat = List.map(rows, row => {
      let poly_strs = String.split(row, ",")->List.fromArray
      List.map(poly_strs, P.from_string)
    })
    mat
  }
}

module type Kyber_t = {
  type poly_mat
  type public_key = (poly_mat, poly_mat)
  type private_key = poly_mat
  type ciphertext = (poly_mat, poly_mat)

  let public_key_to_string: public_key => string
  let private_key_to_string: private_key => string
  let ciphertext_to_string: ciphertext => string
  let public_key_from_string: string => public_key
  let private_key_from_string: string => private_key
  let ciphertext_from_string: string => ciphertext
  let generate_keypair: unit => (string, string)
  let encrypt: (string, bytes) => string
  let decrypt: (string, string) => bytes
}

module Make_Kyber = (C: Kyber_Config_sig): Kyber_t => {
  module Polynomial = Make_polynomial(C)
  module PolyMat = Make_poly_mat(Polynomial)

  type poly_mat = PolyMat.t
  type public_key = (poly_mat, poly_mat)
  type private_key = poly_mat
  type ciphertext = (poly_mat, poly_mat)
  let q = C.q
  let k = C.k
  let n1 = C.n1
  let n2 = C.n2

  let public_key_to_string = (pub_key: public_key): string => {
    let a = PolyMat.to_string(fst(pub_key))
    let t = PolyMat.to_string(snd(pub_key))
    a ++ ("|" ++ t)
  }

  let private_key_to_string = (priv_key: private_key): string => PolyMat.to_string(priv_key)

  let ciphertext_to_string = (cipher: ciphertext): string => {
    let u = PolyMat.to_string(fst(cipher))
    let v = PolyMat.to_string(snd(cipher))
    u ++ ("|" ++ v)
  }

  let public_key_from_string = (s: string): public_key => {
    let split = String.split(s, "|")->List.fromArray
    let a = PolyMat.from_string(List.getExn(split, 0))
    let t = PolyMat.from_string(List.getExn(split, 1))
    (a, t)
  }

  let private_key_from_string = (s: string): private_key => PolyMat.from_string(s)

  let ciphertext_from_string = (s: string): ciphertext => {
    let split = String.split(s, "|")->List.fromArray
    let u = PolyMat.from_string(List.getExn(split, 0))
    let v = PolyMat.from_string(List.getExn(split, 1))
    (u, v)
  }

  let generate_keypair = _ => {
    let priv_key: private_key = PolyMat.random_small_coeff(k, 1, n1)
    let a = PolyMat.reduce_matrix(PolyMat.random(k, k))
    let error = PolyMat.reduce_matrix(PolyMat.random_small_coeff(k, 1, n1))
    let t = PolyMat.reduce_matrix(PolyMat.add(PolyMat.mul(a, priv_key), error))
    let pub_key: public_key = (a, t)

    let x = (public_key_to_string(pub_key), private_key_to_string(priv_key))
    x
  }

  let encrypt = (pub_key: string, message: bytes): string => {
    let pub_key = public_key_from_string(pub_key)
    let calculate_u = (a: PolyMat.t, r: PolyMat.t, e1: PolyMat.t): PolyMat.t => {
      let a_transpose = PolyMat.transpose(a)
      let mul_r = PolyMat.mul(a_transpose, r)
      let add_e1 = PolyMat.add(mul_r, e1)
      add_e1
    }

    let calculate_v = (
      t: PolyMat.t,
      r: PolyMat.t,
      e2: PolyMat.t,
      scaled_msg: PolyMat.t,
    ): PolyMat.t => {
      let t_transpose = PolyMat.transpose(t)
      let mul_r = PolyMat.mul(t_transpose, r)
      let add_e2 = PolyMat.add(mul_r, e2)
      let add_msg = PolyMat.add(add_e2, scaled_msg)
      add_msg
    }

    let r = PolyMat.reduce_matrix(PolyMat.random_small_coeff(k, 1, n1))
    let e1 = PolyMat.reduce_matrix(PolyMat.random_small_coeff(k, 1, n2))
    let e2 = PolyMat.reduce_matrix(PolyMat.random_small_coeff(1, 1, n2))
    let scaled_msg = Polynomial.scalar_mul((q + 1) / 2, Polynomial.binary_to_poly(message))
    let zero_mat = PolyMat.zero(1, 1)
    let scaled_msg_mat = PolyMat.set_poly(zero_mat, 0, 0, scaled_msg)
    let u = calculate_u(fst(pub_key), r, e1)

    let v = calculate_v(snd(pub_key), r, e2, scaled_msg_mat)
    let x = ciphertext_to_string((u, v))
    x
  }

  let decrypt = (s: string, cipher: string): bytes => {
    let s = private_key_from_string(s)
    // Js.log(s)
    let cipher = ciphertext_from_string(cipher)
    let u = fst(cipher)
    // Js.log(PolyMat.to_string(u))
    let v = snd(cipher)

    let noisy_result = PolyMat.sub(v, PolyMat.mul(PolyMat.transpose(s), u))
    let noisy_poly = PolyMat.get_poly(noisy_result, 0, 0)
    let rounded_poly = Polynomial.round(noisy_poly)
    let result_poly = Polynomial.scalar_div((q + 1) / 2, rounded_poly)
    let result = Polynomial.poly_to_binary(result_poly)
    result
  }
}
