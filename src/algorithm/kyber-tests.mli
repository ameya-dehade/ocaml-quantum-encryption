(** CRYSTALS-Kyber Testing Interface

    This module provides a comprehensive suite of tests for the CRYSTALS-Kyber implementation.
    The tests cover the main functionalities, including key generation, encapsulation, and
    decapsulation, as well as all supporting operations like polynomial arithmetic, hashing,
    random number generation, and utility functions.

    This test suite ensures that the implementation conforms to the official specification and
    performs correctly under various scenarios.

    The tests are organized as follows:
    - {!module:TestParams} : Tests for parameter validation.
    - {!module:TestPoly} : Tests for polynomial operations.
    - {!module:TestPolyvec} : Tests for polynomial vector operations.
    - {!module:TestHash} : Tests for cryptographic hash functions.
    - {!module:TestRandom} : Tests for random number generation.
    - {!module:TestKyber} : Tests for the main Kyber KEM functions.
    - {!module:TestUtils} : Tests for utility functions.
*)

(* ========================================================================== *)
(** {1 Parameter Validation Tests} *)

module TestParams : sig
    (** Tests for validating the correctness of the parameters defined in the
        {!module:Params} module. These tests ensure that the parameters are
        correctly set according to the Kyber specification and have valid values. *)
  
    val test_params_values : unit -> bool
    (** [test_params_values ()] verifies that the parameters [n], [q], [k], [eta1], [eta2], [du], [dv],
        and [sym_bytes] are set correctly according to the specification. *)
  
    val test_prime_modulus : unit -> bool
    (** [test_prime_modulus ()] checks that the modulus [Params.q] is a prime number,
        which is essential for the correctness of polynomial arithmetic and NTT operations. *)
  end
  
  (* ========================================================================== *)
  (** {1 Polynomial Tests} *)
  
  module TestPoly : sig
    (** Tests for polynomial operations defined in the {!module:Poly} module.
  
        These tests verify the correctness of polynomial arithmetic, transformations,
        serialization, and compression.
    *)
  
    val test_addition : unit -> bool
    (** [test_addition ()] checks that polynomial addition is performed correctly modulo [Params.q]. *)
  
    val test_multiplication : unit -> bool
    (** [test_multiplication ()] verifies that polynomial multiplication is correct
        in the ring [R_q = Z_q[x]/(x^n + 1)]. *)
  
    val test_ntt_transform : unit -> bool
    (** [test_ntt_transform ()] checks that the NTT and inverse NTT transformations
        are correctly implemented and invertible. *)
  
    val test_serialization : unit -> bool
    (** [test_serialization ()] ensures that polynomials are correctly serialized and
        deserialized without loss of data. *)
  
    val test_compression : unit -> bool
    (** [test_compression ()] verifies that polynomial compression and decompression
        are consistent and approximate the original polynomial within acceptable bounds. *)
  end
  
  (* ========================================================================== *)
  (** {1 Polynomial Vector Tests} *)
  
  module TestPolyvec : sig
    (** Tests for polynomial vector operations defined in the {!module:Polyvec} module.
  
        These tests verify the correctness of vector arithmetic, transformations, and
        serialization functions.
    *)
  
    val test_vector_addition : unit -> bool
    (** [test_vector_addition ()] checks that vector addition is performed correctly
        for polynomial vectors. *)
  
    val test_vector_ntt : unit -> bool
    (** [test_vector_ntt ()] verifies that the NTT is correctly applied to each polynomial
        in the vector and that the inverse NTT restores the original vector. *)
  
    val test_vector_serialization : unit -> bool
    (** [test_vector_serialization ()] ensures that polynomial vectors are serialized
        and deserialized correctly. *)
  
    val test_vector_compression : unit -> bool
    (** [test_vector_compression ()] checks that vector compression and decompression
        work correctly within acceptable error bounds. *)
  end
  
  (* ========================================================================== *)
  (** {1 Hash Function Tests} *)
  
  module TestHash : sig
    (** Tests for cryptographic hash functions in the {!module:Hash} module.
  
        These tests ensure that the hash functions produce consistent outputs and
        match expected values from known test vectors.
    *)
  
    val test_kdf : unit -> bool
    (** [test_kdf ()] verifies that the key derivation function produces the expected
        output based on the input key and context. *)
  end
  
  (* ========================================================================== *)
  (** {1 Random Number Generation Tests} *)
  
  module TestRandom : sig
    (** Tests for randomness functions in the {!module:Random} module.
  
        These tests ensure that the random number generator produces secure and
        unbiased outputs.
    *)
  
    val test_random_bytes : unit -> bool
    (** [test_random_bytes ()] verifies that the random byte generator produces
        non-repeating, cryptographically secure outputs. *)
  
    val test_seed_expander : unit -> bool
    (** [test_seed_expander ()] checks that the seed expander produces deterministic
        pseudorandom outputs based on the given seed. *)
  end
  
  (* ========================================================================== *)
  (** {1 Kyber Algorithm Tests} *)
  
  module TestKyber : sig
    (** Tests for the main Kyber KEM functions in the {!module:Kyber} module.
  
        These tests verify the correctness of key generation, encapsulation, and
        decapsulation, and ensure that the shared secret is consistently agreed upon
        by both parties.
    *)
  
    val test_keygen : unit -> bool
    (** [test_keygen ()] checks that key generation produces valid public and secret keys
        that can be used for encapsulation and decapsulation. *)
  
    val test_encapsulation_decapsulation : unit -> bool
    (** [test_encapsulation_decapsulation ()] verifies that the encapsulated shared secret
        can be correctly decapsulated by the recipient, ensuring consistency of the shared secret. *)
  
    val test_public_key_serialization : unit -> bool
    (** [test_public_key_serialization ()] ensures that public keys are serialized and
        deserialized correctly without loss of data. *)
  
    val test_secret_key_serialization : unit -> bool
    (** [test_secret_key_serialization ()] ensures that secret keys are serialized and
        deserialized correctly, maintaining data integrity. *)
  
    val test_ciphertext_serialization : unit -> bool
    (** [test_ciphertext_serialization ()] checks that ciphertexts are correctly serialized
        and deserialized. *)
  
    val test_robustness : unit -> bool
    (** [test_robustness ()] verifies the algorithm's robustness against modified ciphertexts,
        ensuring that decapsulation fails gracefully when the ciphertext is tampered with. *)
  end
  
  (* ========================================================================== *)
  (** {1 Utility Function Tests} *)
  
  module TestUtils : sig
    (** Tests for utility functions in the {!module:Utils} module.
  
        These tests cover the correctness of auxiliary functions such as sampling from
        the centered binomial distribution and matrix generation.
    *)
  
    val test_cbd : unit -> bool
    (** [test_cbd ()] verifies that the centered binomial distribution function correctly
        samples small polynomials based on input entropy. *)
  
    val test_generate_matrix : unit -> bool
    (** [test_generate_matrix ()] checks that the public matrix [A] is generated correctly
        based on the seed and matches known test vectors when transposed or non-transposed. *)
  end
  
  (* ========================================================================== *)
  (** {1 Test Runner} *)
  
  val run_all_tests : unit -> unit
  (** [run_all_tests ()] executes all test modules and reports the results.
  
      This function runs all defined tests, printing a summary of passed and failed tests
      and any error messages encountered during execution. *)
  