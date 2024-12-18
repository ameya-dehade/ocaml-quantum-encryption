(lang dune 3.16)

(generate_opam_files true)

(authors "Ameya Dehade" "Neil Patel")

(maintainers "ameyadehade@gmail.com")

(package
 (name ocaml_quantum_encryption)
 (allow_empty)
 (synopsis
  "An OCaml library for Quantum Encryption for key and message exchange")
 (description
  "This library is an implementation of the Kyber Key Encapsulation Mechanism (KEM) 
  with all Kyber specifications. It provides secure key establishment for post-quantum
  cryptographic schemes. It also includes functions for encrypting and decrypting 
  messages using AES-GCM.")
 (depends
  (ounit2
   (>= 2.2.7))
  (core
   (>= 0.17.1))
  (mirage-crypto
   (>= 1.1.0))
  (mirage-crypto-rng
   (>= 1.1.0))
  (mirage-crypto-rng-async
   (>= 1.1.0))
  ))
