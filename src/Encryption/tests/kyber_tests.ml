open OUnit2
open Kyber
(* Kyber Module Tests *)
let setup _ =
  Mirage_crypto_rng_unix.initialize (module Mirage_crypto_rng.Fortuna)

module Polynomial = Make_polynomial(Kyber768_Config)
module KyberKEM = Make_Kyber(Kyber768_Config)

let test_binary_to_poly _ =
  let message = Bytes.of_string "\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01" in
  let poly = Polynomial.binary_to_poly message in
  let expected = Polynomial.from_coefficients [0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1] in
  assert_equal poly expected

let test_poly_to_binary _ =
  let poly = Polynomial.from_coefficients [0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1] in
  let message = Polynomial.poly_to_binary poly in
  let expected = Bytes.of_string "\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01" in
  assert_equal message expected

let test_kyber_encryption_decryption_fixed _ =
  let (pub_key, priv_key) = KyberKEM.generate_keypair () in
  let message = Bytes.of_string "\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01\x01\x00\x01\x01" in
  let cipher = KyberKEM.encrypt pub_key message in
  let decrypted = KyberKEM.decrypt priv_key cipher in
  assert_equal message decrypted

let test_kyber_encryption_decryption_random _ =
  setup ();
  let (pub_key, priv_key) = KyberKEM.generate_keypair () in
  let shared_secret = Mirage_crypto_rng.generate 32 in
  let cipher = KyberKEM.encrypt pub_key (Bytes.of_string shared_secret) in
  let decrypted = KyberKEM.decrypt priv_key cipher in
  assert_equal shared_secret (Bytes.to_string decrypted)

let test_kyber_encryption_decryption_10_random_ =
  setup ();
  let (pub_key, priv_key) = KyberKEM.generate_keypair () in
  for _ = 1 to 1000 do
    let shared_secret = Mirage_crypto_rng.generate 32 in
    let cipher = KyberKEM.encrypt pub_key (Bytes.of_string shared_secret) in
    let decrypted = KyberKEM.decrypt priv_key cipher in
    assert_equal shared_secret (Bytes.to_string decrypted)
  done

(* Test Suite *)
let kyber_suite =
  "kyber_test_suite" >::: [
    "test_binary_to_poly" >:: test_binary_to_poly;
    "test_poly_to_binary" >:: test_poly_to_binary;
    "test_kyber_encryption_decryption_fixed" >:: test_kyber_encryption_decryption_fixed;
    "test_kyber_encryption_decryption_random" >:: test_kyber_encryption_decryption_random
  ]
