// // Bindings for Web Crypto API
// @scope("window") 
// @val external crypto: {..} = "crypto"
// @scope("crypto") 
// @val external subtle: {..} = "subtle"

type algorithmIdentifier = {
  name: string,
  length: int
}

let algo = "AES-GCM"

let algorithm: algorithmIdentifier = {
  name: "AES-GCM",
  length: 256,
}

let keyUsages = ["encrypt", "decrypt"]

let format = "raw"

@val @scope(("window", "crypto"))
external getRandomValues: 
  (
    Js.Typed_array.Uint8Array.t
  ) 
  => 
  Js.Typed_array.Uint8Array.t = "getRandomValues"


@val @scope(("window", "crypto", "subtle"))
external generateKey: 
  (
    algorithmIdentifier, bool, array<string>
  ) 
  => 
  promise<{..}> = "generateKey"

@val @scope(("window", "crypto", "subtle"))
external exportKey: 
  (
    string, 
    {..}
  ) 
  => 
  promise<Js.Typed_array.array_buffer> = "exportKey"

@val @scope(("window", "crypto", "subtle"))
external encrypt: 
  (
    {..}, 
    {..},
    Js.Typed_array.array_buffer, 
  ) 
  => 
  promise<Js.Typed_array.array_buffer> = "encrypt"

@val @scope(("window", "crypto", "subtle"))
external importKey: 
  (
    string, 
    Js.Typed_array.array_buffer, 
    algorithmIdentifier, 
    bool, 
    array<string>
  ) 
  => 
  promise<{..}> = "importKey"

@val @scope(("window", "crypto", "subtle"))
external decrypt: 
  (
    {..}, 
    {..},
    Js.Typed_array.array_buffer, 
  ) 
  => 
  promise<Js.Typed_array.array_buffer> = "decrypt"

let arrayBufferToBytes = (arrayBuffer: Js.Typed_array.ArrayBuffer.t) : bytes => {
  let uint8Array = Js.Typed_array.Uint8Array.fromBuffer(arrayBuffer)
  let bytesLength = Js.Typed_array.Uint8Array.byteLength(uint8Array)
  let bytes = Bytes.create(bytesLength)
  
  for i in 0 to bytesLength - 1 {
    let intValue = uint8Array->Js.Typed_array.Uint8Array.unsafe_get(i)
    Bytes.set(bytes, i, Char.chr(intValue))
  }
  
  bytes
}

let bytesToArrayBuffer = (bytes: bytes) : Js.Typed_array.ArrayBuffer.t => {
  let bytesLength = Bytes.length(bytes)
  let uint8Array = Js.Typed_array.Uint8Array.fromLength(bytesLength)
  
  for i in 0 to bytesLength - 1 {
    let byte = Bytes.get(bytes, i)
    let intValue = Char.code(byte)
    uint8Array->Js.Typed_array.Uint8Array.unsafe_set(i, intValue)
  }
  
  Js.Typed_array.Uint8Array.buffer(uint8Array)
}

open Kyber
module KyberKEM = Make_Kyber(Kyber768_Config)

// Function to generate a shared key 
let generateSharedKey = async () => {
  try {
    let keyObject = await generateKey(algorithm, true, keyUsages)
    let key = await exportKey(format, keyObject)
    key
  } catch {
  | _ => Js.Exn.raiseError("Failed to generate key")
  }
}

let generate_keypair_for_new_user = () => {
  KyberKEM.generate_keypair()
}

let decrypt_recieved_shared_key = (my_priv_key: string, cipher: string) => {
  let decrypted = KyberKEM.decrypt(my_priv_key, cipher)
  decrypted
}

let generate_and_encrypt_shared_key = async (their_pub_key: string) => {
  let sharedKey = await generateSharedKey()
  let bytes_val = arrayBufferToBytes(sharedKey)
  let encryptedSharedKey = KyberKEM.encrypt(their_pub_key, bytes_val)
  let result = {
    "sharedKey": bytes_val,
    "encryptedSharedKey": encryptedSharedKey
  }
  result
}

let create_crypto_key = async (shared_key : string) => {
  let shared_key_bytes = Bytes.of_string(shared_key)
  let shared_key_raw = bytesToArrayBuffer(shared_key_bytes)
  let shared_crypto_key = await importKey(format, shared_key_raw, algorithm, true, keyUsages)
  shared_crypto_key
}

let encrypt_message = async (shared_key: string, message: bytes) => {
  // Encrypt message using AES_GCM from Web Crypto API
  try {
    let shared_crypto_key = await create_crypto_key(shared_key)
    let nonce = getRandomValues(Js.Typed_array.Uint8Array.fromLength(12))
    let algorithm_obj = {
      "name" : algo,
      "iv" : nonce
    }
    let nonce_string = arrayBufferToBytes(Js.Typed_array.Uint8Array.buffer(nonce))->Bytes.to_string
    let encrypted = await encrypt(algorithm_obj, shared_crypto_key, bytesToArrayBuffer(message))
    let encrypted_string = arrayBufferToBytes(encrypted)->Bytes.to_string
    (nonce_string, encrypted_string)
  } catch {
    | err => {
      Js.Console.error(`Failed to encrypt message: ${Obj.magic(err)}`)
      Js.Exn.raiseError("Failed to encrypt message")
    }
  }
}

let decrypt_message = async (shared_key: string, nonce: string, cipher: string) => {
  // Encrypt message using AES_GCM from Web Crypto API
  try {
    let shared_crypto_key = await create_crypto_key(shared_key)
    let nonce_array = Bytes.of_string(nonce)->bytesToArrayBuffer
    let algorithm_obj = {
      "name" : algo,
      "iv" : nonce_array
    }
    let decrypted = await decrypt(algorithm_obj, shared_crypto_key, bytesToArrayBuffer(cipher->Bytes.of_string))
    let decrypted_bytes = arrayBufferToBytes(decrypted)
    decrypted_bytes
  } catch {
    | err => {
      Js.Console.error(`Failed to encrypt message: ${Obj.magic(err)}`)
      Js.Exn.raiseError("Failed to encrypt message")
    }
  }
}