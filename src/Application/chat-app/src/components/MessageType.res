type messageType = 
  | Login
  | Chat
  | UserList

type t = {
  type_: messageType,
  from: string,
  message: string,
  timestamp: string
}