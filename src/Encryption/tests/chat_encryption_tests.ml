open OUnit2
open Chat_encryption

let () = ChatEncryption.randomness_setup ()

let test_generate_new_shared_key _ =
  let shared_key = ChatEncryption.generate_new_shared_key () in
  assert_equal 32 (String.length shared_key)

let test_encrypt_decrypt_shared_key _ =
  let pub_key, priv_key = ChatEncryption.generate_keypair_for_new_user () in
  let shared_key = ChatEncryption.generate_new_shared_key () in
  let encrypted_shared_key = ChatEncryption.encrypt_shared_key_for_sending ~shared_key ~their_pub_key:pub_key in
  let decrypted_shared_key = ChatEncryption.decrypt_recieved_shared_key ~my_priv_key:priv_key ~cipher:encrypted_shared_key in
  assert_equal shared_key decrypted_shared_key

let test_encrypt_decrypt_message _ =
  let shared_key = ChatEncryption.generate_new_shared_key () in
  let message = Bytes.of_string "Hello, world!" in
  let nonce, cipher = ChatEncryption.encrypt_message ~shared_key ~message in
  match ChatEncryption.decrypt_message ~shared_key ~nonce ~cipher with
  | Ok decrypted_message -> assert_equal message decrypted_message
  | Error _ -> assert_failure "Decryption failed"  

  (* Simulate the establishment of communication between user1 and user2, and then an exchange of messages *)
let test_full_workflow _ =
  (* When user is created, keypairs are generated *)
  let (_user1_pub_key, _user1_priv_key) = ChatEncryption.generate_keypair_for_new_user () in
  let (user2_pub_key, user2_priv_key) = ChatEncryption.generate_keypair_for_new_user () in
  (* User 1 creates a shared key to share *)
  let shared_secret = ChatEncryption.generate_new_shared_key () in
  (* User 1 encrypts the shared key for sending to user 2 *)
  let encrypted_shared_key = ChatEncryption.encrypt_shared_key_for_sending ~shared_key:shared_secret ~their_pub_key:user2_pub_key in
  (* User 2 recieves and decrypts the shared key *)
  let decrypted_shared_key = ChatEncryption.decrypt_recieved_shared_key ~my_priv_key:user2_priv_key ~cipher:encrypted_shared_key in
  (* User 2 encrypts a message to send to user 1 *)
  let message = Bytes.of_string "Hello, friend!" in
  let nonce, cipher = ChatEncryption.encrypt_message ~shared_key:decrypted_shared_key ~message in
  (* User 1 decrypts the message *)
  match ChatEncryption.decrypt_message ~shared_key:shared_secret ~nonce ~cipher with
  | Ok decrypted_message -> assert_equal message decrypted_message
  | Error _ -> assert_failure "Decryption failed"

  let chat_encryption_suite =
  "ChatEncryption Tests" >::: [
    "test_generate_new_shared_key" >:: test_generate_new_shared_key;
    "test_encrypt_decrypt_shared_key" >:: test_encrypt_decrypt_shared_key;
    "test_encrypt_decrypt_message" >:: test_encrypt_decrypt_message;
    "test_full_workflow" >:: test_full_workflow
  ]

let () =
  run_test_tt_main chat_encryption_suite