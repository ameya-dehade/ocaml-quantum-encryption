(** Kyber - Post-quantum cryptographic algorithm implementation *)

open Bigarray

(** {2 Types} *)

(** Represents elements in the ring R_q = Z_q[X]/(X^n + 1) *)
type polynomial

(** Represents a vector of polynomials *)
type polynomial_vector

(** Represents a matrix of polynomials *)
type polynomial_matrix

(** Parameter sets for different security levels *)
type parameter_set = {
  k: int;          (** Module rank *)
  eta1: int;       (** Noise parameter for secret key *)
  eta2: int;       (** Noise parameter for encryption *)
  du: int;         (** Compression parameter for ciphertext u *)
  dv: int;         (** Compression parameter for ciphertext v *)
  n: int;          (** Polynomial degree (fixed at 256) *)
  q: int;          (** Modulus (fixed at 3329) *)
}

(** {2 Constants} *)

(** Predefined parameter sets *)
val kyber512  : parameter_set
val kyber768  : parameter_set
val kyber1024 : parameter_set

(** {2 Core Ring Operations} *)

(** Number Theoretic Transform operations:
The objective of NTT is to multiply 2 polynomials such that the coefficient 
of the resultant polynomials are calculated under a particular modulo *)
module NTT : sig
  val forward : polynomial -> polynomial
  val inverse : polynomial -> polynomial
  val multiply : polynomial -> polynomial -> polynomial
end

(** {2 Polynomial Operations} *)

(** Create a polynomial from coefficients *)
val polynomial_create : int array -> polynomial

(** Get coefficients from a polynomial *)
val polynomial_coefficients : polynomial -> int array

(** Add two polynomials *)
val polynomial_add : polynomial -> polynomial -> polynomial

(** Subtract two polynomials *)
val polynomial_sub : polynomial -> polynomial -> polynomial

(** Multiply two polynomials (using NTT) *)
val polynomial_mul : polynomial -> polynomial -> polynomial

(** {2 Sampling Functions} *)

(** Parse bytes into polynomial *)
val parse : bytes -> polynomial

(** Sample polynomial from centered binomial distribution *)
val sample_cbd : int -> bytes -> polynomial

(** Generate uniform random polynomial *)
val sample_uniform : unit -> polynomial

(** {2 Compression and Encoding} *)

(** Compression functions *)
val compress_q : int -> int -> int
val decompress_q : int -> int -> int

(** Encode polynomial to bytes *)
val encode : int -> polynomial -> bytes

(** Decode bytes to polynomial *)
val decode : int -> bytes -> polynomial

(** {2 Vector/Matrix Operations} *)

(** Create polynomial vector *)
val vector_create : polynomial array -> polynomial_vector

(** Get polynomials from vector *)
val vector_polynomials : polynomial_vector -> polynomial array

(** Create polynomial matrix *)
val matrix_create : polynomial array array -> polynomial_matrix

(** Get polynomials from matrix *)
val matrix_polynomials : polynomial_matrix -> polynomial array array

(** Matrix-vector multiplication *)
val matrix_vector_mul : polynomial_matrix -> polynomial_vector -> polynomial_vector

(** Inner product of polynomial vectors *)
val vector_inner_product : polynomial_vector -> polynomial_vector -> polynomial

(** {2 Public Key Encryption (PKE)} *)

module CPAPKE : sig
  type public_key
  type secret_key
  type ciphertext

  (** Key generation *)
  val keygen : parameter_set -> public_key * secret_key

  (** Encryption *)
  val encrypt : parameter_set -> public_key -> bytes -> bytes -> ciphertext

  (** Decryption *)
  val decrypt : parameter_set -> secret_key -> ciphertext -> bytes
end

(** {2 Key Encapsulation Mechanism (KEM)} *)

module CCAKEM : sig
  type public_key
  type secret_key
  type ciphertext
  type shared_key = bytes

  (** Key generation *)
  val keygen : parameter_set -> public_key * secret_key

  (** Encapsulation *)
  val encapsulate : parameter_set -> public_key -> ciphertext * shared_key

  (** Decapsulation *)
  val decapsulate : parameter_set -> secret_key -> ciphertext -> shared_key
end

(** {2 Cryptographic Primitives} *)

(** Pseudo-random function *)
val prf : bytes -> bytes -> bytes

(** Extendable output function *)
val xof : bytes -> bytes -> bytes -> bytes

(** Hash functions *)
val hash_h : bytes -> bytes
val hash_g : bytes -> bytes * bytes

(** Key derivation function *)
val kdf : bytes -> bytes