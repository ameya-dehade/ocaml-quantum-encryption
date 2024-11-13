(** Kyber Correctness Tests Interface *)

(** Tests the correctness of Kyber.CPAPKE key generation.
    Verifies that the generated public key and secret key are of the expected length and format. *)
    val test_kyber_cpapke_keygen : unit -> bool

    (** Tests the correctness of Kyber.CPAPKE encryption and decryption.
        Ensures that decrypting an encrypted message returns the original message. *)
    val test_kyber_cpapke_encrypt_decrypt : unit -> bool
    
    (** Tests the correctness of Kyber.CCAKEM key generation.
        Verifies that the keys generated conform to the expected format and size. *)
    val test_kyber_ccakem_keygen : unit -> bool
    
    (** Tests the correctness of Kyber.CCAKEM encapsulation and decapsulation.
        Checks that the shared secret derived from encapsulation and decapsulation matches. *)
    val test_kyber_ccakem_encaps_decaps : unit -> bool
    
    (** Tests the handling of compression and decompression functions in Kyber.
        Verifies that decompressing a compressed value yields a close approximation of the original value. *)
    val test_compression_decompression : unit -> bool
    
    (** Tests the correctness of NTT and inverse NTT transformations.
        Ensures that applying NTT followed by its inverse returns the original polynomial. *)
    val test_ntt_inverse_ntt : unit -> bool
    
    (** Tests uniform sampling in Rq.
        Checks if the sampled elements conform statistically to a uniform distribution. *)
    val test_uniform_sampling : unit -> bool
    
    (** Tests the correctness of the centered binomial distribution (CBD) sampling.
        Verifies that the sampled noise follows the expected distribution. *)
    val test_cbd_sampling : unit -> bool
    