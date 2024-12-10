@react.component
let make = (~currentUser: string) => {
  open MessageType;
  let (messages, setMessages) = React.useState((): array<MessageType.t> => []);
  let (socket, setSocket) = React.useState(() => None);
  let (availableUsers, setAvailableUsers) = React.useState(() => []);
  let (selectedUser, setSelectedUser) = React.useState(() => None);
  let (sharedKeys, setSharedKeys) = React.useState(() => Js.Dict.empty());

  // Import encryption functions
  Encryption.randomnessSetup()
  let (pubKey, privKey) = Encryption.generateKeypair();
  let (sharedKey, _) = Encryption.generateAndEncryptSharedKey(~theirPubKey=pubKey)

    // Serialize the public key
  // let serializePublicKey = (~pubKey: Encryption.publicKey): string => {
  //   let (part1, part2) = pubKey;
  //   part1 ++ "," ++ part2; // Combine parts with a separator
  // }

  // // Deserialize the public key
  // let deserializePublicKey = (~serializedKey: string): Encryption.publicKey => {
  //   let parts = serializedKey->Js.String.split(",");
  //   (Belt.Array.getExn(parts, 0), Belt.Array.getExn(parts, 1)); // Extract parts
  // }

  // Key Exchange Logic
  let initiateKeyExchange = (~recipient: string, ~theirPubKey: string) => {
    let (sharedKey, encryptedKey) = Encryption.generateAndEncryptSharedKey(~theirPubKey);
    switch socket {
    | Some(ws) =>
        let keyExchangeMessage = Js.Dict.empty();
        Js.Dict.set(keyExchangeMessage, "type", Js.Json.string("keyExchange"));
        Js.Dict.set(keyExchangeMessage, "from", Js.Json.string(currentUser));
        Js.Dict.set(keyExchangeMessage, "to", Js.Json.string(recipient));
        Js.Dict.set(keyExchangeMessage, "encryptedKey", Js.Json.string(encryptedKey));
        ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(keyExchangeMessage)));

        // Store the shared key locally
        Js.Dict.set(sharedKeys, recipient, sharedKey);
    | None => Js.log("WebSocket not connected")
    }
  }

  // let handleKeyExchangeResponse = (~from: string, ~encryptedKey: string) => {
  //   switch Encryption.decryptSharedKey(~myPrivKey=privKey, ~cipher=encryptedKey) {
  //   | Ok(key) =>
  //       Js.Dict.set(sharedKeys, from, key); // Store the decrypted shared key
  //       Js.log("Shared key successfully decrypted and stored for: " ++ from);
  //   | Error(err) =>
  //       Js.log("Failed to decrypt shared key for user " ++ from ++ ": " ++ err);
  //   };
  // };

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
          Js.Dict.set(loginData, "pubKey", Js.Json.string(pubKey));
          
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
                // Decrypt the message
                let encryptedMessage = messageObj->Js.Dict.get("message")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                let nonce = messageObj->Js.Dict.get("nonce")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                let decryptedMessage = Encryption.decryptMessage(~sharedKey, ~nonce, ~cipher=encryptedMessage)
                
                // Safely extract required fields with defaults
                let newMessage = {
                  type_: messageType == Some("privateChat") ? PrivateChat : Chat,
                  from: messageObj->Js.Dict.get("from")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault("Unknown"),
                  to_: messageObj->Js.Dict.get("to")
                    ->Belt.Option.flatMap(Js.Json.decodeString),
                  message: decryptedMessage->Belt.Result.map(Bytes.to_string)->Belt.Result.getWithDefault(""),
                  timestamp: messageObj->Js.Dict.get("timestamp")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(""),
                }
                
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
        // No user selected
        Js.log("No user selected")
        ()
      }
    }
    
    Js.Dict.set(messageData, "from", Js.Json.string(currentUser))
    Js.Dict.set(messageData, "timestamp", Js.Json.string(timestamp))
    
    // Encrypt the message
    let (nonce, encryptedMessage) = Encryption.encryptMessage(~sharedKey, ~message=Bytes.of_string(message))
    Js.Dict.set(messageData, "message", Js.Json.string(encryptedMessage))
    Js.Dict.set(messageData, "nonce", Js.Json.string(nonce))
    
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

  let handleUserSelect = user => {
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
        {switch selectedUser {
        | Some(user) => 
          <>
            <div className="text-lg font-bold mb-2">
              {React.string("Chat with " ++ user)}
            </div>
            <div className="flex-1 overflow-y-scroll mb-4 bg-white rounded-lg p-2">
              {switch messages {
              | [] => <p className="text-gray-500 text-center"> {React.string("No messages yet!")} </p>
              | _ =>
                messages
                ->Belt.Array.keepMap(msg => 
                  switch (selectedUser, msg.type_) {
                  | (Some(selectedUserName), PrivateChat) => 
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
          </>
        | None => 
          <div className="text-lg font-bold mb-2 text-center">
            {React.string("Pick a user to chat with")}
          </div>
        }}
      </div>
    </div>
  </div>;
}