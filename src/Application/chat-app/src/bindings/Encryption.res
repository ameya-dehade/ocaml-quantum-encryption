let randomnessSetup = () => {
  Js.log("randomnessSetup called");
  Random.self_init();
};

let generateKeypair = () => {
  Js.log("generateKeypair called");
  (string_of_int(Random.int(100)), string_of_int(Random.int(100)));
};

let generateAndEncryptSharedKey = (~theirPubKey: string) => {
  Js.log("generateAndEncryptSharedKey called");
  let sharedKey = string_of_int(Random.int(100));
  (sharedKey, sharedKey);
};

let decryptSharedKey = (~myPrivKey: string, ~cipher: string) => {
  Js.log("decryptSharedKey called");
  cipher;
};

let encryptMessage = (~sharedKey: string, ~message: bytes) => {
  Js.log("encryptMessage called");
  (string_of_int(Random.int(100)), Bytes.to_string(message));
};

let decryptMessage = (~sharedKey: string, ~nonce: string, ~cipher: string) => {
  Js.log("decryptMessage called");
  Bytes.of_string(cipher);
};