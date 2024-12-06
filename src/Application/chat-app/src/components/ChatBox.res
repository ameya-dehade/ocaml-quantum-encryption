@react.component
let make = (~currentUser: string) => {
  open MessageType
  let (messages, setMessages) = React.useState((): array<MessageType.t> => [])
  let (socket, setSocket) = React.useState(() => None)
  let (availableUsers, setAvailableUsers) = React.useState(() => [])

  React.useEffect1(() => {
    switch socket {
    | None => {
        let ws = WebSocket.make("ws://localhost:8080")
        
        ws->WebSocket.onOpen(() => {
          Js.log("Connected to WebSocket")
          
          // Send login message
          let loginData = Js.Dict.empty()
          Js.Dict.set(loginData, "type", Js.Json.string("login"))
          Js.Dict.set(loginData, "username", Js.Json.string(currentUser))
          
          ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(loginData)))
          
          setSocket(_ => Some(ws))
        })

        ws->WebSocket.onMessage(event => {
          try {
            let message = Js.Json.parseExn(event["data"])
            let messageObj = message->Js.Json.decodeObject->Belt.Option.getExn
            
            let messageType = messageObj->Js.Dict.get("type")
              ->Belt.Option.flatMap(Js.Json.decodeString)
            
            switch messageType {
            | Some("chat") => {
                // Safely extract required fields with defaults
                let newMessage = {
                  type_: Chat,
                  from: messageObj->Js.Dict.get("from")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault("Unknown"),
                  message: messageObj->Js.Dict.get("message")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(""),
                  timestamp: messageObj->Js.Dict.get("timestamp")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(Js.Date.toISOString(Js.Date.make())),
                }
                
                setMessages(prev => 
                  if prev->Belt.Array.some(existingMsg => 
                    existingMsg.from == newMessage.from && 
                    existingMsg.message == newMessage.message && 
                    existingMsg.timestamp == newMessage.timestamp
                  ) {
                    prev
                  } else {
                    Belt.Array.concat(prev, [newMessage])
                  }
                )
              }
            | Some("userList") => {
                let users = messageObj->Js.Dict.get("users")
                  ->Belt.Option.flatMap(Js.Json.decodeArray)
                  ->Belt.Option.map(arr => 
                    arr->Belt.Array.keepMap(item => 
                      item->Js.Json.decodeString
                    )
                  )
                  ->Belt.Option.getWithDefault([])
                  // Use a Set to ensure unique users and remove current user
                  ->Belt.Set.String.fromArray
                  ->Belt.Set.String.remove(currentUser)
                  ->Belt.Set.String.toArray
                
                setAvailableUsers(_ => users)
              }
            | _ => ()
            }
          } catch {
          | _ => Js.log("Error parsing message")
          }
        })

        ws->WebSocket.onClose(_ => {
          Js.log("WebSocket connection closed")
          setSocket(_ => None)
        })
      }
    | Some(_) => ()
    }

    Some(() => {
      switch socket {
      | Some(ws) => {
          ws->WebSocket.onClose(_ => ())
          setSocket(_ => None)
        }
      | None => ()
      }
    })
  }, [])
  
  let handleSendMessage = message => {
    let timestamp = Js.Date.toISOString(Js.Date.make())
    let messageData = Js.Dict.empty()
    Js.Dict.set(messageData, "type", Js.Json.string("chat"))
    Js.Dict.set(messageData, "from", Js.Json.string(currentUser))
    Js.Dict.set(messageData, "message", Js.Json.string(message))
    Js.Dict.set(messageData, "timestamp", Js.Json.string(timestamp))
    
    switch socket {
    | Some(ws) => ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(messageData)))
    | None => ()
    }
  }

  <div className="p-4 bg-slate-200 w-full h-full flex flex-col rounded-lg">
    <div className="flex">
      <div className="w-1/4 pr-4">
        <h2 className="text-lg font-bold mb-4">{React.string("Available Users")}</h2>
        <ul className="bg-white rounded-lg p-2">
          {Belt.Array.length(availableUsers) > 0 
            ? availableUsers->Belt.Array.mapWithIndex((idx, user) => 
              <li 
                key={Belt.Int.toString(idx)} 
                className="p-2 hover:bg-gray-100 cursor-pointer"
              >
                {React.string(user)}
              </li>
            )->React.array
            : <li className="text-gray-500 text-center">
                {React.string("No other users online")}
              </li>
          }
        </ul>
      </div>
      <div className="w-3/4 flex flex-col">
        <div className="flex-1 overflow-y-scroll mb-4 bg-white rounded-lg p-2">
          {switch messages {
          | [] => <p className="text-gray-500 text-center"> {React.string("No messages yet!")} </p>
          | _ =>
            messages
            ->Belt.Array.mapWithIndex((idx, msg) =>
              <div key={Belt.Int.toString(idx)} className="mb-2">
                <div>
                  <span className="font-bold"> {React.string(msg.from ++ ": ")} </span>
                  <span> {React.string(msg.message)} </span>
                </div>
                <div className="text-xs text-gray-500"> {React.string(msg.timestamp)} </div>
              </div>
            )
            ->React.array
          }}
        </div>
        <ChatInput onSubmit={handleSendMessage} />
      </div>
    </div>
  </div>
}