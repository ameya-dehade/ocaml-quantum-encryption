type publicKey = string;
type privateKey = string;
type ciphertext = string;

// @module("../../../../Encryption/chat_encryption/chat_encryption")
// external randomnessSetup: unit => unit = "randomness_setup"

// @module("../../../../Encryption/chat_encryption/chat_encryption") 
// external generateKeypair: unit => (publicKey, privateKey) = "generate_keypair_for_new_user"

// @module("../../../../Encryption/chat_encryption/chat_encryption")
// external generateAndEncryptSharedKey: (~theirPubKey: publicKey) => (string, ciphertext) = "generate_and_encrypt_shared_key"

// @module("../../../../Encryption/chat_encryption/chat_encryption") 
// external decryptSharedKey: (~myPrivKey: privateKey, ~cipher: ciphertext) => string = "decrypt_recieved_shared_key"

// @module("../../../../Encryption/chat_encryption/chat_encryption")
// external encryptMessage: (~sharedKey: string, ~message: bytes) => (string, string) = "encrypt_message"

// @module("../../../../Encryption/chat_encryption/chat_encryption")
// external decryptMessage: (~sharedKey: string, ~nonce: string, ~cipher: string) => result<bytes, string> = "decrypt_message"

let randomnessSetup = () => {
  Js.log("randomnessSetup called");
};

let generateKeypair = () => {
  Js.log("generateKeypair called");
  ("dummy_pub_key", "dummy_priv_key");
};

let generateAndEncryptSharedKey = (~theirPubKey: publicKey) => {
  Js.log("generateAndEncryptSharedKey called");
  ("dummy_shared_key", "dummy_cipher");
};

let decryptSharedKey = (~myPrivKey: privateKey, ~cipher: ciphertext) => {
  Js.log("decryptSharedKey called");
  "dummy_decrypted_shared_key";
};

let encryptMessage = (~sharedKey: string, ~message: bytes) => {
  Js.log("encryptMessage called");
  ("dummy_nonce", "dummy_encrypted_message");
};

let decryptMessage = (~sharedKey: string, ~nonce: string, ~cipher: string) => {
  Js.log("decryptMessage called");
  Ok(Bytes.of_string("dummy_decrypted_message"));
};