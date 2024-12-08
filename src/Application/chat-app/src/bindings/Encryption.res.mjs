// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Chat_encryption from "../../../Encryption/chat_encryption/chat_encryption";

function randomnessSetup(prim) {
  Chat_encryption.randomness_setup();
}

function generateKeypair(prim) {
  return Chat_encryption.generate_keypair_for_new_user();
}

function generateSharedKey(prim) {
  return Chat_encryption.generate_new_shared_key();
}

function encryptSharedKey(prim0, prim1) {
  return Chat_encryption.encrypt_shared_key_for_sending(prim0, prim1);
}

function decryptSharedKey(prim0, prim1) {
  return Chat_encryption.decrypt_recieved_shared_key(prim0, prim1);
}

function encryptMessage(prim0, prim1) {
  return Chat_encryption.encrypt_message(prim0, prim1);
}

function decryptMessage(prim0, prim1, prim2) {
  return Chat_encryption.decrypt_message(prim0, prim1, prim2);
}

export {
  randomnessSetup ,
  generateKeypair ,
  generateSharedKey ,
  encryptSharedKey ,
  decryptSharedKey ,
  encryptMessage ,
  decryptMessage ,
}
/* ../../../Encryption/chat_encryption/chat_encryption Not a pure module */
