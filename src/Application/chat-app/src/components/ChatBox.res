@react.component
let make = (~currentUser: string) => {
  open MessageType;
  let (messages, setMessages) = React.useState((): array<MessageType.t> => []);
  let (socket, setSocket) = React.useState(() => None);
  let (availableUsers, setAvailableUsers) = React.useState(() => []);
  let (selectedUser, setSelectedUser) = React.useState(() => None);
  let (sharedKeys, setSharedKeys) = React.useState(() => Js.Dict.empty());
  let (publicKeys, setPublicKeys) = React.useState(() => Js.Dict.empty());
  let (pubKey, setPubKey) = React.useState(() => "");
  let (privKey, setPrivKey) = React.useState(() => "");

  React.useEffect0(() => {
    // Call your function here
    Encryption.randomnessSetup();
    Js.log("Generating keypair")
    let (s_pubKey, s_privKey) = Encryption.generateKeypair();
    Js.log(s_pubKey)
    Js.log(s_privKey)
    setPubKey(_ => s_pubKey);
    setPrivKey(_ => s_privKey);
    Some(() => ());;
  });

  // Key Exchange Logic
  let performKeyExchange = (~recipient: string, ~theirPubKey: string) => {
    let (sharedKey, encryptedSharedKey) = Encryption.generateAndEncryptSharedKey(~theirPubKey);
    Js.log("Generated shared key")
    Js.log(sharedKey)
    Js.log(encryptedSharedKey)
    switch socket {
    | Some(ws) =>
        let keyExchangeMessage = Js.Dict.empty();
        Js.Dict.set(keyExchangeMessage, "type", Js.Json.string("keyExchange"));
        Js.Dict.set(keyExchangeMessage, "from", Js.Json.string(currentUser));
        Js.Dict.set(keyExchangeMessage, "to", Js.Json.string(recipient));
        Js.Dict.set(keyExchangeMessage, "encryptedSharedKey", Js.Json.string(encryptedSharedKey));
        ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(keyExchangeMessage)));

        // Store the shared key locally
        let newSharedKeys = Js.Dict.fromArray(Js.Dict.entries(sharedKeys))
        Js.Dict.set(newSharedKeys, recipient, sharedKey);
        setSharedKeys(_ => newSharedKeys)
    | None => Js.log("WebSocket not connected")
    }
  }

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
            | Some("privateChat") => {
                // Decrypt the message
                let encryptedMessage = messageObj->Js.Dict.get("message")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                let nonce = messageObj->Js.Dict.get("nonce")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                let sharedKey = Js.Dict.unsafeGet(sharedKeys, messageObj->Js.Dict.get("from")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("Unknown"))
                let decryptedMessage = Encryption.decryptMessage(~sharedKey, ~nonce, ~cipher=encryptedMessage);
                Js.log("Message sender")
                Js.log(messageObj->Js.Dict.get("from")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("Unknown"))

                // Safely extract required fields with defaults
                let newMessage = {
                  msg_type: PrivateChat,
                  from: messageObj->Js.Dict.get("from")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault("Unknown"),
                  to_: messageObj->Js.Dict.get("to")
                    ->Belt.Option.flatMap(Js.Json.decodeString),
                  message: decryptedMessage->Bytes.to_string,
                  timestamp: messageObj->Js.Dict.get("timestamp")
                    ->Belt.Option.flatMap(Js.Json.decodeString)
                    ->Belt.Option.getWithDefault(""),
                }
                setMessages(prev => 
                    Belt.Array.concat(prev, [newMessage])
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
            | Some("keyExchange") => {
                Js.log("Received key exchange request")
                
                let from = messageObj->Js.Dict.get("from")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("Unknown")
                let encryptedSharedKey = messageObj->Js.Dict.get("encryptedSharedKey")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                
                // Decrypt the shared key
                let sharedKey = Encryption.decryptSharedKey(~myPrivKey=privKey, ~cipher=encryptedSharedKey);
                Js.log("Decrypted shared key")
                Js.log(sharedKey)
                let newSharedKeys = Js.Dict.fromArray(Js.Dict.entries(sharedKeys))
                Js.Dict.set(newSharedKeys, from, sharedKey)
                setSharedKeys(_ => newSharedKeys)
              }
            | Some("publicKeyInfo") => {
                Js.log("Received public key info")
                
                let user = messageObj->Js.Dict.get("from")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("Unknown")
                let publicKey = messageObj->Js.Dict.get("publicKeyInfo")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("")
                
                Js.log("Parsed public key info:")
                Js.log(user)
                Js.log(publicKey)
        
                let newPublicKeys = Js.Dict.fromArray(Js.Dict.entries(publicKeys))
                Js.Dict.set(newPublicKeys, user, publicKey)
                setPublicKeys(_ => newPublicKeys)
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
    let sharedKey = Js.Dict.unsafeGet(sharedKeys, Js.Option.getExn(selectedUser))
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
            msg_type: PrivateChat,
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
    switch Js.Dict.get(sharedKeys, user) {
    | Some(_) => setSelectedUser(_ => Some(user))
    | None => {
        // Request the public key for the user
        switch socket {
        | Some(_ws) => 
        Js.log("Requesting public key for user: " ++ user)
        let pubkey = Js.Dict.unsafeGet(publicKeys, user)
        performKeyExchange(~recipient=user, ~theirPubKey=pubKey)
        Js.log(pubKey)
        setSelectedUser(_ => Some(user))
        | None => Js.log("WebSocket not connected")
        }
      }
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
                  switch (selectedUser, msg.msg_type) {
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