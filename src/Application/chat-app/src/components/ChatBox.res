@react.component
let make = (~currentUser: string) => {
  open MessageType
  let (messages, setMessages) = React.useState((): array<MessageType.t> => [])
  let (socket, setSocket) = React.useState(() => None)
  let (availableUsers, setAvailableUsers) = React.useState(() => [])
  let (selectedUser, setSelectedUser) = React.useState(() => None)

  // Initialize randomness for encryption
  React.useEffect1(() => {
    Encryption.randomnessSetup();
    None;
  }, [])

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
            | Some("chat") | Some("privateChat") => {
                // Safely extract required fields with defaults
                let newMessage = {
                  type_: messageType == Some("privateChat") ? PrivateChat : Chat,
                  from: messageObj->Js.Dict.get("from")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault("Unknown"),
                  to_: messageObj->Js.Dict.get("to")
                    ->Belt.Option.flatMap(Js.Json.decodeString),
                  message: messageObj->Js.Dict.get("message")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(""),
                  timestamp: messageObj->Js.Dict.get("timestamp")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(Js.Date.toISOString(Js.Date.make())),
                }
                
                // Add the message if it's a global chat, 
                // or a private chat that involves the current user
                setMessages(prev => 
                  if prev->Belt.Array.some(existingMsg => 
                    existingMsg.from == newMessage.from && 
                    existingMsg.message == newMessage.message && 
                    existingMsg.timestamp == newMessage.timestamp
                  ) {
                    prev
                  } else if (
                    newMessage.type_ == Chat || 
                    (newMessage.type_ == PrivateChat && (
                      newMessage.from == currentUser || 
                      newMessage.to_ == Some(currentUser)
                    ))
                  ) {
                    Belt.Array.concat(prev, [newMessage])
                  } else {
                    prev
                  }
                )
              }
            | Some("userList") => {
                Js.log("Received user list")
                
                let users = switch Js.Json.decodeObject(message) {
                | Some(obj) => {
                    switch Js.Dict.get(obj, "users") {
                    | Some(usersJson) => {
                        switch Js.Json.decodeArray(usersJson) {
                        | Some(arr) => arr
                          ->Belt.Array.keepMap(item => Js.Json.decodeString(item))
                          // Remove current user and use Belt.Set to eliminate duplicates
                          ->Belt.Set.String.fromArray
                          ->Belt.Set.String.remove(currentUser)
                          ->Belt.Set.String.toArray
                        | None => []
                        }
                    }
                    | None => []
                    }
                }
                | None => []
                }
                
                Js.log("Parsed users:")
                Js.log(users)
                
                setAvailableUsers(_ => users)
              }
            | _ => ()
            }
          } catch {
          | err => {
              Js.log("Error parsing message")
              Js.log(err)
            }
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
    
    switch selectedUser {
    | Some(user) => {
        // Private message
        Js.Dict.set(messageData, "type", Js.Json.string("privateChat"))
        Js.Dict.set(messageData, "to", Js.Json.string(user))
      }
    | None => {
        // Global chat
        Js.Dict.set(messageData, "type", Js.Json.string("chat"))
      }
    }
    
    Js.Dict.set(messageData, "from", Js.Json.string(currentUser))
    Js.Dict.set(messageData, "message", Js.Json.string(message))
    Js.Dict.set(messageData, "timestamp", Js.Json.string(timestamp))
    
    switch socket {
    | Some(ws) => {
        // Send the message
        ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(messageData)))
        
        // Immediately add the message to the local messages state
        setMessages(prev => {
          let newMessage = {
            type_: switch selectedUser {
            | Some(_) => PrivateChat
            | None => Chat
            },
            from: currentUser,
            to_: selectedUser,
            message: message,
            timestamp: timestamp
          }
          
          Belt.Array.concat(prev, [newMessage])
        })
      }
    | None => ()
    }
  }

  let handleUserSelect = (user) => {
    setSelectedUser(_ => Some(user))
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
                className={
                  "p-2 hover:bg-gray-100 cursor-pointer " ++ 
                  (selectedUser == Some(user) ? "bg-blue-100" : "")
                }
                onClick={_ => handleUserSelect(user)}
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
        <div className="text-lg font-bold mb-2">
          {switch selectedUser {
          | Some(user) => React.string("Chat with " ++ user)
          | None => React.string("Global Chat")
          }}
          {selectedUser->Belt.Option.mapWithDefault(
            <button 
              className="ml-4 text-sm text-blue-600 hover:text-blue-800"
              onClick={_ => setSelectedUser(_ => None)}
            >
              {React.string("Global Chat")}
            </button>,
            _ => React.null
          )}
        </div>
        <div className="flex-1 overflow-y-scroll mb-4 bg-white rounded-lg p-2">
          {switch messages {
          | [] => <p className="text-gray-500 text-center"> {React.string("No messages yet!")} </p>
          | _ =>
            messages
            ->Belt.Array.keepMap(msg => 
              switch (selectedUser, msg.type_) {
              | (None, Chat) => Some(msg)
              | (Some(selectedUserName), PrivateChat) => 
                // Only show messages where the selected user is either sender or recipient
                if (
                  (msg.from == selectedUserName && msg.to_ == Some(currentUser)) || 
                  (msg.from == currentUser && msg.to_ == Some(selectedUserName))
                ) {
                  Some(msg)
                } else {
                  None
                }
              | _ => None
              }
            )
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