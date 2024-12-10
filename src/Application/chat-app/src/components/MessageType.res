type messageType = 
  | Login
  | PrivateChat
  | PublicKeyRequest
  | KeyExchange
  | KeyExchangeResponse
  | UserList

type t = {
  msg_type: messageType,
  from: string,
  to_: option<string>,
  message: string,
  timestamp: string
}