(** 
  Module for chat encryption using Kyber and AES-GCM.

  This module provides functions to generate key pairs, shared keys, 
  and to encrypt/decrypt messages for secure chat communication.

  - `generate_keypair_for_new_user ()`:
    Generates a new Kyber key pair for a new user.
    @return A tuple containing the public and private keys.

  - `generate_new_shared_key ()`:
    Generates a new shared key for encryption.
    @return A 32-byte shared key.

  - `encrypt_shared_key_for_sending ~shared_key ~their_pub_key`:
    Encrypts a shared key using the recipient's public key.
    @param shared_key The shared key to be encrypted.
    @param their_pub_key The recipient's public key.
    @return The encrypted shared key.

  - `decrypt_recieved_shared_key ~my_priv_key ~cipher`:
    Decrypts a received shared key using the user's private key.
    @param my_priv_key The user's private key.
    @param cipher The encrypted shared key.
    @return The decrypted shared key as a string.

  - `encrypt_message ~key message`:
    Encrypts a message using AES-GCM with the provided key.
    @param key The encryption key.
    @param message The message to be encrypted.
    @return A tuple containing the nonce and the encrypted message.

  - `decrypt_message ~key ~nonce cipher`:
    Decrypts a message using AES-GCM with the provided key and nonce.
    @param key The encryption key.
    @param nonce The nonce used during encryption.
    @param cipher The encrypted message.
    @return [Ok plaintext] if decryption is successful, [Error "Decryption failed"] otherwise.
*)
open Kyber

module ChatEncryption = struct

  module Polynomial = Make_polynomial(Kyber_Config)
  module KyberKEM = Make_Kyber(Kyber_Config)(Polynomial)
  type public_key = KyberKEM.public_key
  type private_key = KyberKEM.private_key
  type ciphertext = KyberKEM.ciphertext
  
  let randomness_setup () =
    Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna)

  let generate_keypair_for_new_user () =
    KyberKEM.generate_keypair ()

  let generate_new_shared_key () =
    Mirage_crypto_rng.generate 32

  let encrypt_shared_key_for_sending ~shared_key ~their_pub_key =
    let cipher = KyberKEM.encrypt their_pub_key (Bytes.of_string shared_key) in
    cipher
    
  let decrypt_recieved_shared_key ~my_priv_key ~cipher =
    let decrypted = KyberKEM.decrypt my_priv_key cipher in
    Bytes.to_string decrypted

  let encrypt_message ~shared_key ~message =
    let nonce = Mirage_crypto_rng.generate 12 in
    let cipher = 
      Mirage_crypto.AES.GCM.authenticate_encrypt 
        ~key:(Mirage_crypto.AES.GCM.of_secret shared_key)
        ~nonce:nonce
        (Bytes.to_string message)
    in
    (nonce, cipher)

  let decrypt_message ~shared_key ~nonce ~cipher =
    match Mirage_crypto.AES.GCM.authenticate_decrypt
            ~key:(Mirage_crypto.AES.GCM.of_secret shared_key)
            ~nonce:nonce
            cipher with
    | Some plaintext -> Ok (Bytes.of_string plaintext)
    | None -> Error "Decryption failed"
end