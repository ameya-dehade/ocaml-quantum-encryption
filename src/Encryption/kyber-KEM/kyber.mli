(** Kyber (Key Encapsulation Mechanism) is a post-quantum cryptographic scheme
  that provides secure key establishment. This implementation follows a simplified
  version of the Kyber specification.

  The scheme consists of three main components:
  - Key Generation: Produces a public-private key pair
  - Encryption: Encrypts a message using the public key
  - Decryption: Decrypts a ciphertext using the private key

  {2 Security Parameters}
  The scheme is parameterized by several constants defined in the Kyber_Config_sig:
  - q: The modulus for polynomial arithmetic
  - n: The degree of polynomials
  - k: The dimension of polynomial vectors
  - n1: The parameter for small coefficient sampling in noise generation
  - n2: Additional parameter for small coefficient sampling

  {2 Mathematical Background}
  Operations are performed in the ring R_q = Z_q[X]/(X^n + 1), where:
  - Z_q is the ring of integers modulo q
  - Polynomials are reduced modulo (X^n + 1)
  - Coefficients are reduced modulo q

  {2 Implementation Notes}
  - All polynomial operations are implemented in the Polynomial module
  - Matrix operations are handled by the PolyMat module
  - Random sampling is used for key generation and encryption
  - The implementation includes noise sampling for security

  {2 Usage Example}
  {[
    let (public_key, private_key) = KyberKEM.generate_keypair () in
    let message = "secret message" in
    let ciphertext = KyberKEM.encrypt public_key message in
    let decrypted = KyberKEM.decrypt private_key ciphertext
  ]}

  @see 'Polynomial' for polynomial arithmetic operations
  @see 'PolyMat' for matrix operations

*)

(** Baby Kyber Library Interface *)

module type Kyber_Config_sig = sig
  val q : int
  val n : int
  val k : int
  val n1 : int
  val n2 : int
end

module Kyber512_Config : Kyber_Config_sig
module Kyber768_Config : Kyber_Config_sig
module Kyber1024_Config : Kyber_Config_sig
module Test_Kyber_Config_Mini : Kyber_Config_sig

(** 
  Module type for polynomial operations.
  @type t - Abstract type representing a polynomial.
  @val modulus_q - The modulus value for polynomial coefficients.
  @val modulus_poly - The modulus polynomial represented as a list of coefficients.
  @val zero - The zero polynomial.
  @val add - Adds two polynomials.
  @val sub - Subtracts the second polynomial from the first.
  @val mul - Multiplies two polynomials.
  @val scalar_mul - Multiplies a polynomial by a scalar.
  @val scalar_div - Divides a polynomial by a scalar.
  @val reduce - Reduces a polynomial modulo the modulus polynomial.
  @val add_and_reduce - Adds two polynomials and reduces the result.
  @val sub_and_reduce - Subtracts the second polynomial from the first and reduces the result.
  @val mul_and_reduce - Multiplies two polynomials and reduces the result.
  @val round - Rounds the coefficients of a polynomial to around an input value.
  @val binary_to_poly - Converts a byte sequence to a polynomial.
  @val poly_to_binary - Converts a polynomial to a byte sequence.
  @val from_coefficients - Creates a polynomial from a list of coefficients.
  @val to_coefficients - Converts a polynomial to a list of coefficients.
  @val to_string - Converts a polynomial to its string representation.
  @val random - Generates a random polynomial.
  @val random_small_coeff - Generates a random polynomial with small coefficients.
*)

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

(** 
  Functor to create a polynomial module given a configuration.
  @param _ - Module adhering to Kyber_Config_sig.
  @return - Module adhering to Polynomial_t.
*)
module Make_polynomial : functor (_ : Kyber_Config_sig) -> Polynomial_t

(** 
  Module type for polynomial matrix operations.
  @type t - Abstract type representing a polynomial matrix.
  @type poly - Type representing a polynomial.
  @val zero - Creates a zero matrix with given dimensions.
  @val add - Adds two matrices.
  @val sub - Subtracts the second matrix from the first.
  @val scalar_mul - Multiplies a matrix by a scalar.
  @val scalar_div - Divides a matrix by a scalar.
  @val transpose - Transposes a matrix.
  @val dot_product - Computes the dot product of two polynomial lists.
  @val mul - Multiplies two matrices.
  @val random - Generates a random matrix with given dimensions.
  @val random_small_coeff - Generates a random matrix with small coefficients.
  @val get_poly - Gets the polynomial at a specific position in the matrix.
  @val set_poly - Sets the polynomial at a specific position in the matrix.
  @val map_poly - Applies a function to each polynomial in the matrix.
  @val reduce_matrix - Reduces each polynomial in the matrix.
  @val to_list - Converts a matrix to a list of polynomial lists.
  @val from_list - Creates a matrix from a list of polynomial lists.
  @val to_string - Converts a matrix to its string representation.
  @val from_string - Creates a matrix from its string representation.
  @val dimensions - Returns the dimensions of the matrix.
*)
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

(** 
  Functor to create a polynomial matrix module given a polynomial module.
  @param _ - Module adhering to Polynomial_t.
  @return - Module adhering to PolyMat_t.
*)
module Make_poly_mat : functor (P : Polynomial_t) -> PolyMat_t with type poly = P.t

(** 
  Module type for Kyber key encapsulation mechanism (KEM).
  @type poly_mat - Type representing a polynomial matrix.
  @type public_key - Type representing a public key, which is a pair of polynomial matrices.
  @type private_key - Type representing a private key, which is a polynomial matrix.
  @type ciphertext - Type representing a ciphertext, which is a pair of polynomial matrices.
  @val generate_keypair - Generates a public/private key pair.
  @val encrypt - Encrypts a message using a public key.
  @val decrypt - Decrypts a ciphertext using a private key.
*)
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

(** 
  Functor to create a Kyber KEM module given a configuration and a polynomial module.
  @param _ - Module adhering to Kyber_Config_sig.
  @return - Module adhering to Kyber_t.
*)
module Make_Kyber : functor (_ : Kyber_Config_sig) -> Kyber_t