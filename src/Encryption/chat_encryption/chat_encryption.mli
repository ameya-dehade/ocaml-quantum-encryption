open Kyber
open KyberKEM

(** 
  Module for chat encryption functionalities.
*)

module ChatEncryption : sig
  val randomness_setup : unit -> unit
  
  (** 
    Generates a new key pair for starting a new chat.
    @return A tuple containing the public key and private key.
  *)
  val generate_keypair_for_new_user : unit -> public_key * private_key

  (** 
    Generates a new shared key for encryption.
    @return The generated shared key as bytes.
  *)
  val generate_new_shared_key : unit -> string

  (** 
    Encrypts a shared key for sending to another party.
    @param shared_key The shared key to be encrypted.
    @param their_pub_key The public key of the recipient.
    @return The encrypted shared key as bytes.
  *)
  val encrypt_shared_key_for_sending : shared_key:string -> their_pub_key:public_key -> ciphertext

  (** 
    Decrypts a received shared key.
    @param my_priv_key The private key of the recipient.
    @param cipher The encrypted shared key.
    @return The decrypted shared key as a string.
  *)
  val decrypt_recieved_shared_key : my_priv_key:private_key -> cipher:ciphertext -> string

  (** 
    Encrypts a message using a given key.
    @param key The key to use for encryption.
    @param message The message to be encrypted.
    @return A tuple containing the nonce and the encrypted message as bytes.
  *)
  val encrypt_message : shared_key:string -> message:bytes -> string * string

  (** 
    Decrypts an encrypted message using a given key and nonce.
    @param key The key to use for decryption.
    @param nonce The nonce used during encryption.
    @param cipher The encrypted message.
    @return A result containing the decrypted message as bytes on success, or an error message as a string on failure.
  *)
  val decrypt_message : shared_key:string -> nonce:string -> cipher:string -> (bytes, string) result
end