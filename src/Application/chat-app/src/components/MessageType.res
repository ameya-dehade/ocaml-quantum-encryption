type messageType = 
  | Login
  | Chat
  | PrivateChat
  | UserList

type t = {
  type_: messageType,
  from: string,
  to_: option<string>,
  message: string,
  timestamp: string
}