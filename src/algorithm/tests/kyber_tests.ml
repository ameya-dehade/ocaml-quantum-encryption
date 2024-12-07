open OUnit2
open Kyber

(* Kyber Module Tests *)
let test_kyber_keypair_generation _ =
  let (pub_key, priv_key) = Kyber.generate_keypair () in
  assert_bool "Public key first component not null" (fst pub_key <> PolyMat.zero 2 2);
  assert_bool "Public key second component not null" (snd pub_key <> PolyMat.zero 1 2);
  assert_bool "Private key not null" (priv_key <> PolyMat.zero 1 2)

let test_kyber_encryption_decryption _ =
  let (pub_key, priv_key) = Kyber.generate_keypair () in
  let message = Bytes.of_string "\x01\x00\x01\x01" in
  let cipher = Kyber.encrypt pub_key message in
  let decrypted = Kyber.decrypt priv_key cipher in
  assert_equal message decrypted

(* Test Suite *)
let kyber_suite =
  "kyber_test_suite" >::: [
    "test_kyber_keypair_generation" >:: test_kyber_keypair_generation;
    "test_kyber_encryption_decryption" >:: test_kyber_encryption_decryption;
  ]
