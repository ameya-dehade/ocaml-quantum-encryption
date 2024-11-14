(** CRYSTALS-Kyber Key Encapsulation Mechanism Interface

    This module provides an implementation of the CRYSTALS-Kyber algorithm,
    a post-quantum key encapsulation mechanism based on the hardness of
    the Module Learning with Errors (MLWE) problem over rings.

    The implementation includes key generation, encapsulation, and decapsulation functions,
    along with all necessary supporting modules for polynomial arithmetic,
    cryptographic hashing, random number generation, and parameter definitions.

    The modules are organized as follows:
    - {!module:Params} : Algorithm parameters.
    - {!module:Types} : Type definitions used throughout the implementation.
    - {!module:Poly} : Polynomial operations modulo [x^n + 1] and [q].
    - {!module:Polyvec} : Operations on vectors of polynomials.
    - {!module:Hash} : Cryptographic hash functions.
    - {!module:Random} : Random number generation functions.
    - {!module:Kyber} : Main Kyber algorithm functions.
    - {!module:Utils} : Utility functions.

    @author
    @version
    @see <https://pq-crystals.org/kyber/> Official Kyber Specification
*)

(* ========================================================================== *)
(** {1 Parameters} *)

module Params : sig
  (** Algorithm parameters for the CRYSTALS-Kyber implementation.

      This module defines the fundamental parameters used throughout the Kyber algorithm,
      including the polynomial degree, modulus, and distribution parameters.

      These parameters are critical for ensuring the correct security level and performance
      of the implementation.
  *)

  val n : int
  (** [n] is the degree of the polynomials used in the ring [R = Z_q[x]/(x^n + 1)].
      Typically, [n = 256]. *)

  val q : int
  (** [q] is the modulus for the polynomial coefficients.
      Typically, [q = 3329], which is a prime number facilitating efficient NTT. *)

  val k : int
  (** [k] is the security parameter indicating the number of polynomials in a vector.
      Common values are [k = 2], [k = 3], or [k = 4], corresponding to Kyber512, Kyber768, and Kyber1024. *)

  val eta1 : int
  (** [eta1] is the parameter for the centered binomial distribution used during key generation
      for sampling secret and error polynomials. *)

  val eta2 : int
  (** [eta2] is the parameter for the centered binomial distribution used during encapsulation
      for sampling secret polynomials. *)

  val du : int
  (** [du] is the bit-width for compressing the first part of the ciphertext. *)

  val dv : int
  (** [dv] is the bit-width for compressing the second part of the ciphertext. *)

  val sym_bytes : int
  (** [sym_bytes] is the size of shared secrets and hash outputs in bytes, typically 32 bytes (256 bits). *)

  (* Additional parameters may be added as per the specification. *)
end

(* ========================================================================== *)
(** {1 Type Definitions} *)

module Types : sig
  (** Type definitions used throughout the Kyber algorithm implementation.

      This module defines custom types representing polynomials, vectors of polynomials,
      public keys, secret keys, ciphertexts, and shared secrets.

      These types provide a clear and consistent representation of the various data structures
      used in the algorithm.
  *)

  type poly
  (** [poly] represents a polynomial with coefficients modulo [Params.q] in the ring [R_q]. *)

  type polyvec
  (** [polyvec] represents a vector of [Params.k] polynomials.
      It is used to represent keys and ciphertext components. *)

  type public_key
  (** [public_key] represents a Kyber public key, which includes a vector of polynomials
      and a seed for matrix generation. *)

  type secret_key
  (** [secret_key] represents a Kyber secret key, which includes a vector of polynomials
      and other necessary information for decapsulation. *)

  type ciphertext
  (** [ciphertext] represents a Kyber ciphertext, consisting of compressed polynomial vectors. *)

  type shared_secret
  (** [shared_secret] represents the shared secret derived from the encapsulation and decapsulation
      processes. *)

end

(* ========================================================================== *)
(** {1 Polynomial Operations} *)

module Poly : sig
  (** Operations on polynomials modulo [x^n + 1] and [Params.q].

      This module provides functions for polynomial arithmetic, including addition,
      subtraction, multiplication, and negation, all performed in the ring [R_q].

      It also includes functions for applying the Number Theoretic Transform (NTT)
      and its inverse, serialization, compression, and sampling polynomials from
      random or seeded inputs.
  *)

  type t = Types.poly
  (** [t] is the type alias for polynomials in this module. *)

  val zero : t
  (** [zero] is the zero polynomial, where all coefficients are zero modulo [Params.q]. *)

  val one : t
  (** [one] is the polynomial representing the multiplicative identity, with coefficient 1 at degree 0
      and zero elsewhere. *)

  val add : t -> t -> t
  (** [add a b] computes the polynomial addition [a + b] modulo [Params.q]. *)

  val sub : t -> t -> t
  (** [sub a b] computes the polynomial subtraction [a - b] modulo [Params.q]. *)

  val mul : t -> t -> t
  (** [mul a b] computes the polynomial multiplication [a * b] modulo [x^n + 1] and [Params.q]. *)

  val neg : t -> t
  (** [neg a] computes the additive inverse of polynomial [a], i.e., [-a] modulo [Params.q]. *)

  val ntt : t -> t
  (** [ntt a] computes the Number Theoretic Transform of polynomial [a],
      transforming it into the NTT domain for efficient convolution. *)

  val inv_ntt : t -> t
  (** [inv_ntt a] computes the inverse Number Theoretic Transform of polynomial [a],
      transforming it back from the NTT domain. *)

  val to_bytes : t -> bytes
  (** [to_bytes a] serializes the polynomial [a] into a byte array representation. *)

  val of_bytes : bytes -> t
  (** [of_bytes b] deserializes the byte array [b] into a polynomial [a]. *)

  val compress : t -> bytes
  (** [compress a] compresses the polynomial [a] into a smaller byte array using lossy compression
      for efficient transmission. *)

  val decompress : bytes -> t
  (** [decompress b] decompresses the byte array [b] back into an approximate polynomial [a]. *)

  val sample : bytes -> t
  (** [sample seed] generates a polynomial [a] by sampling coefficients using a seeded random source. *)

  (* Additional polynomial operations as required by the algorithm may be added here. *)
end

(* ========================================================================== *)
(** {1 Polynomial Vector Operations} *)

module Polyvec : sig
  (** Operations on vectors of polynomials.

      This module provides functions for arithmetic and transformations on vectors
      of polynomials, which are used to represent keys and ciphertext components.

      Functions include element-wise addition, subtraction, scalar multiplication,
      and application of NTT transformations.
  *)

  type t = Types.polyvec
  (** [t] is the type alias for vectors of polynomials in this module. *)

  val zero : t
  (** [zero] is the zero vector, where each polynomial is the zero polynomial. *)

  val add : t -> t -> t
  (** [add a b] computes the element-wise addition of vectors [a] and [b]. *)

  val sub : t -> t -> t
  (** [sub a b] computes the element-wise subtraction of vectors [a] and [b]. *)

  val mul : t -> Types.poly -> t
  (** [mul a b] multiplies each polynomial in vector [a] by the polynomial [b]. *)

  val ntt : t -> t
  (** [ntt a] applies the NTT to each polynomial in vector [a], transforming the entire vector
      into the NTT domain. *)

  val inv_ntt : t -> t
  (** [inv_ntt a] applies the inverse NTT to each polynomial in vector [a]. *)

  val to_bytes : t -> bytes
  (** [to_bytes a] serializes the polynomial vector [a] into a byte array. *)

  val of_bytes : bytes -> t
  (** [of_bytes b] deserializes the byte array [b] into a polynomial vector [a]. *)

  val compress : t -> bytes
  (** [compress a] compresses the polynomial vector [a] into a smaller byte array
      using lossy compression techniques. *)

  val decompress : bytes -> t
  (** [decompress b] decompresses the byte array [b] back into an approximate
      polynomial vector [a]. *)

  val sample : bytes -> t
  (** [sample seed] generates a polynomial vector [a] by sampling each polynomial
      using a seeded random source. *)

  (* Additional vector operations as required by the algorithm may be added here. *)
end

(* ========================================================================== *)
(** {1 Cryptographic Hash Functions} *)

module Hash : sig
  (** Cryptographic hash functions used in the Kyber algorithm.*)

  val hash_h : bytes -> bytes
  (** [hash_h msg] computes the hash of the input message [msg] using the H function. *)

  val hash_g : bytes -> bytes
  (** [hash_g msg] computes the hash of the input message [msg] using the G function. *)

  val kdf : bytes -> Types.shared_secret
  (** [kdf seed] derives a shared key from the input seed using a key derivation function. *)

  (* Additional hash functions or variants may be added as required. *)
end

(* ========================================================================== *)
(** {1 Random Number Generation} *)

module Random : sig
  (** Randomness generation functions for cryptographic purposes.

      This module provides interfaces for generating cryptographically secure
      random bytes, as well as deterministic pseudorandom bytes from a given seed.

      The functions are used for generating secret keys, error polynomials, and
      other random values required by the Kyber algorithm.
  *)

  val random_bytes : int -> bytes
  (** [random_bytes n] generates [n] bytes of cryptographically secure random data. *)

  val seed_expander : bytes -> int -> bytes
  (** [seed_expander seed n] expands the input [seed] deterministically into [n]
      bytes of pseudorandom data using a secure pseudorandom function, such as
      SHAKE128 or SHAKE256. *)

  (* Additional randomness functions as required may be added here. *)
end

(* ========================================================================== *)
(** {1 Utility Functions} *)

module Utils : sig
  (** Utility functions used throughout the Kyber implementation.

      This module includes miscellaneous functions such as sampling from
      the centered binomial distribution and generating the public matrix.

      These functions support the main operations of the algorithm and
      encapsulate common patterns or complex calculations.
  *)

  val cbd : bytes -> int -> Types.poly
  (** [cbd buf eta] samples a polynomial from the centered binomial distribution
      with parameter [eta] using the byte array [buf] as input entropy.

      This function is used for generating secret and error polynomials
      with small coefficients par. *)

  val generate_matrix : bytes -> bool -> Types.polyvec array
  (** [generate_matrix seed transposed] generates the public matrix [A] using
      the provided [seed]. If [transposed] is [true], it generates the transposed
      matrix [A^T].

      The matrix is used in the key generation and encapsulation processes
      and is generated deterministically from the [seed]. *)

  (* Additional utility functions as required by the algorithm may be added here. *)
end

(* ========================================================================== *)
(** {1 Kyber Key Encapsulation Mechanism} *)

module Kyber : sig
  (** Implementation of the main Kyber Key Encapsulation Mechanism (KEM).

      This module provides the primary functions for key generation,
      encapsulation, and decapsulation, as specified in the Kyber algorithm.

      The KEM allows two parties to securely agree on a shared secret over
      an insecure channel.
  *)

  type public_key = Types.public_key
  (** [public_key] is the type alias for Kyber public keys in this module. *)

  type secret_key = Types.secret_key
  (** [secret_key] is the type alias for Kyber secret keys in this module. *)

  type ciphertext = Types.ciphertext
  (** [ciphertext] is the type alias for Kyber ciphertexts in this module. *)

  type shared_secret = Types.shared_secret
  (** [shared_secret] is the type alias for shared secrets in this module. *)

  val keygen : unit -> public_key * secret_key
  (** [keygen ()] generates a Kyber public and secret key pair.

      The function returns a tuple [(pk, sk)], where [pk] is the public key
      and [sk] is the corresponding secret key.

      This function is typically called by the recipient to generate their key pair. *)

  val encapsulate : public_key -> ciphertext * shared_secret
  (** [encapsulate pk] encapsulates a shared secret using the recipient's
      public key [pk].

      The function returns a tuple [(ct, ss)], where [ct] is the ciphertext
      to be sent to the recipient, and [ss] is the shared secret agreed upon
      by the sender.

      This function is typically called by the sender to establish a shared secret
      with the recipient. *)

  val decapsulate : secret_key -> ciphertext -> shared_secret
  (** [decapsulate sk ct] decapsulates the ciphertext [ct] using the recipient's
      secret key [sk], recovering the shared secret [ss].

      This function is typically called by the recipient upon receiving the ciphertext
      to obtain the shared secret agreed upon with the sender. *)

  val public_key_to_bytes : public_key -> bytes
  (** [public_key_to_bytes pk] serializes the public key [pk] into a byte array
      for storage or transmission. *)

  val public_key_of_bytes : bytes -> public_key
  (** [public_key_of_bytes b] deserializes the byte array [b] into a public key [pk]. *)

  val secret_key_to_bytes : secret_key -> bytes
  (** [secret_key_to_bytes sk] serializes the secret key [sk] into a byte array
      for storage. Secret keys should be protected appropriately. *)

  val secret_key_of_bytes : bytes -> secret_key
  (** [secret_key_of_bytes b] deserializes the byte array [b] into a secret key [sk]. *)

  val ciphertext_to_bytes : ciphertext -> bytes
  (** [ciphertext_to_bytes ct] serializes the ciphertext [ct] into a byte array
      for transmission. *)

  val ciphertext_of_bytes : bytes -> ciphertext
  (** [ciphertext_of_bytes b] deserializes the byte array [b] into a ciphertext [ct]. *)
end
