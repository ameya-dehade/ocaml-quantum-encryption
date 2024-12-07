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

module Polynomial : sig
  (** Polynomial operations *)

  type t
  (** Type representing a polynomial *)
 
  val zero : t
  (** The zero polynomial *)

  val add : t -> t -> t
  (** Add two polynomials *)

  val sub : t -> t -> t
  (** Subtract two polynomials *)

  val mul : t -> t -> t
  (** Multiply two polynomials *)

  val scalar_mul : int -> t -> t
  (** Multiply a polynomial by a scalar *)

  val scalar_div : int -> t -> t
  (** Divide a polynomial by a scalar *)

  val reduce : t -> t
  (** Reduce a polynomial modulo q and degree n. If a coefficient is negative, make sure it becomes positive *)

  val add_and_reduce : t -> t -> t
  (** Add two polynomials and reduce the result *)

  val sub_and_reduce : t -> t -> t
  (** Subtract two polynomials and reduce the result *)

  val mul_and_reduce : t -> t -> t
  (** Multiply two polynomials and reduce the result *)

  val round : t -> t
  (** Round a polynomial's coefficients to either q/2 or 0, whichever is closer *)

  val binary_to_poly : bytes -> t
  (** Convert bytes to a binary bits polynomial *)

  val poly_to_binary : t -> bytes
  (** Convert a binary bits polynomial to bytes *)

  val from_coefficients : int list -> t
  (** Create a polynomial from a list of coefficients *)

  val to_coefficients : t -> int list
  (* * Convert a polynomial to a list of coefficients *)

  val to_string : t -> string
  (** Convert a polynomial to a string *)

  val random : unit -> t
  (** Generate a random polynomial of given degree *)

  val random_small_coeff : int -> t
  (** Generate a random polynomial of given degree with small coefficients, as determined by n1 *)
end

module PolyMat : sig
  (** Polynomial Matrix operations *)

  type t
  (** Type representing a matrix of polynomials *)

  val zero : int -> int -> t
  (** Create a zero matrix with given rows and columns *)

  val add : t -> t -> t
  (** Add two polynomial matrices of same dimensions *)

  val sub : t -> t -> t
  (** Subtract two polynomial matrices of same dimensions *)

  val scalar_mul : int -> t -> t
  (** Multiply a polynomial matrix by a scalar *)

  val scalar_div : int -> t -> t
  (** Divide a polynomial matrix by a scalar *)

  val transpose : t -> t
  (** Transpose a polynomial matrix *)

  val dot_product : Polynomial.t list -> Polynomial.t list -> Polynomial.t
  (** Compute the dot product of two lists of polynomials *)

  val mul : t -> t -> t
  (** Multiply two polynomial matrices*)

  val random : int -> int -> t
  (** Generate a random polynomial matrix of given dimensions and polynomial degree *)

  val random_small_coeff : int -> int -> int -> t
  (** Generate a random polynomial matrix of given dimensions and polynomial degree with small coefficients *)

  val get_poly : t -> int -> int -> Polynomial.t
  (** Get a polynomial at a specific position *)

  val set_poly : t -> int -> int -> Polynomial.t -> t
  (** Set a polynomial at a specific position *)

  val map_poly : (Polynomial.t -> Polynomial.t) -> t -> t
  (** Apply a function to each polynomial in the matrix *)

  val reduce_matrix : t -> t
  (** Reduce a polynomial matrix modulo q and degree n *)

  val to_list : t -> Polynomial.t list list
  (** Convert a PolyMat to an Polynomial list of lists *)

  val from_list : Polynomial.t list list -> t
  (* * Convert an Polynomial list of lists to a PolyMat *)

  val to_string : t -> string
  (** Convert a polynomial matrix to a string *)

  val dimensions : t -> int * int
  (** Get the dimensions of a polynomial matrix *)
end

module KyberKEM : sig
  (** Kyber Cryptographic Scheme *)

  type public_key = PolyMat.t * PolyMat.t
  (** Type representing a public key (polynomial vector), A and t *)

  type private_key = PolyMat.t
  (** Type representing a private key (polynomial vector), s *)

  type ciphertext = PolyMat.t * PolyMat.t
  (** Type representing a ciphertext (two polynomial vectors), u and v *)

  val generate_keypair : unit -> public_key * private_key
  (** Generate a public and private key pair *)

  val encrypt : public_key -> bytes -> ciphertext
  (** Encrypt a message given a public key, a polynomial (message), and a random vector *)

  val decrypt : private_key -> ciphertext -> bytes
  (** Decrypt a ciphertext given a private key *)
end