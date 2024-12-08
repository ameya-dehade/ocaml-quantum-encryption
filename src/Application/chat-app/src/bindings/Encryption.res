type publicKey
type privateKey 
type ciphertext

@module("../../../../Encryption/chat_encryption/chat_encryption")
external randomnessSetup: unit => unit = "randomness_setup"

@module("../../../../Encryption/chat_encryption/chat_encryption") 
external generateKeypair: unit => (publicKey, privateKey) = "generate_keypair_for_new_user"

@module("../../../../Encryption/chat_encryption/chat_encryption")
external generateAndEncryptSharedKey: (~theirPubKey: publicKey) => (string, ciphertext) = "generate_and_encrypt_shared_key"

@module("../../../../Encryption/chat_encryption/chat_encryption") 
external decryptSharedKey: (~myPrivKey: privateKey, ~cipher: ciphertext) => string = "decrypt_recieved_shared_key"

@module("../../../../Encryption/chat_encryption/chat_encryption")
external encryptMessage: (~sharedKey: string, ~message: bytes) => (string, string) = "encrypt_message"

@module("../../../../Encryption/chat_encryption/chat_encryption")
external decryptMessage: (~sharedKey: string, ~nonce: string, ~cipher: string) => result<bytes, string> = "decrypt_message"