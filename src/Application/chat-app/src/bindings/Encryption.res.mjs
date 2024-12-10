// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Bytes from "rescript/lib/es6/bytes.js";

function randomnessSetup() {
  console.log("randomnessSetup called");
}

function generateKeypair() {
  console.log("generateKeypair called");
  return [
          "dummy_pub_key",
          "dummy_priv_key"
        ];
}

function generateAndEncryptSharedKey(theirPubKey) {
  console.log("generateAndEncryptSharedKey called");
  return [
          "dummy_shared_key",
          "dummy_cipher"
        ];
}

function decryptSharedKey(myPrivKey, cipher) {
  console.log("decryptSharedKey called");
  return "dummy_decrypted_shared_key";
}

function encryptMessage(sharedKey, message) {
  console.log("encryptMessage called");
  return [
          "dummy_nonce",
          "dummy_encrypted_message"
        ];
}

function decryptMessage(sharedKey, nonce, cipher) {
  console.log("decryptMessage called");
  return {
          TAG: "Ok",
          _0: Bytes.of_string("dummy_decrypted_message")
        };
}

export {
  randomnessSetup ,
  generateKeypair ,
  generateAndEncryptSharedKey ,
  decryptSharedKey ,
  encryptMessage ,
  decryptMessage ,
}
/* No side effect */
