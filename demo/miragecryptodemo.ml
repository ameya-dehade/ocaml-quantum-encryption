open Mirage_crypto

let () =
  let key = AES.GCM.of_secret (Mirage_crypto_rng.generate 16) in
  let nonce = "0123456789ab" in
  let plaintext = "Hello, World!" in

  let ciphertext = AES.GCM.authenticate_encrypt ~key ~nonce plaintext in
  let decrypted = AES.GCM.authenticate_decrypt ~key ~nonce ciphertext in
  Printf.printf "Plaintext: %s\n" (plaintext);
  Printf.printf "Ciphertext: %s\n" (ciphertext);
  match decrypted with
  | Some text -> Printf.printf "Decrypted: %s\n" text
  | None -> Printf.printf "Decryption failed\n"