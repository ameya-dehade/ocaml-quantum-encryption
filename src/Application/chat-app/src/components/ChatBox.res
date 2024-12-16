@react.component
let make = (~currentUser: string) => {
  open MessageType;
  // ChatEncryption.generateSharedKey()
  // ->Promise.then(sharedKey => {
  //   Js.log(sharedKey);
  //   Promise.resolve()
  // })
  // ->ignore;
  let (messages, setMessages) = React.useState((): array<MessageType.t> => []);
  let (socket, setSocket) = React.useState(() => None);
  let (availableUsers, setAvailableUsers) = React.useState(() => []);
  let (selectedUser, setSelectedUser) = React.useState(() => None);
  let (sharedKeys, setSharedKeys) = React.useState(() => Js.Dict.empty());
  // let (privKey, setPrivKey) = React.useState(() => "");
  let (unreadMessages, setUnreadMessages) = React.useState(() => Js.Dict.empty());
  let privKeyRef = React.useRef("");


  // Key Exchange Logic
  let performKeyExchange = (~recipient: string, ~theirPubKey: string, ws) => {
    ChatEncryption.generate_and_encrypt_shared_key(theirPubKey) 
    ->Promise.then(response => {
      Js.log("Generated shared key")
      Js.log(response["sharedKey"])
      // Js.log(response["encryptedSharedKey"])
      let keyExchangeMessage = Js.Dict.empty();
      Js.Dict.set(keyExchangeMessage, "type", Js.Json.string("keyExchange"));
      Js.Dict.set(keyExchangeMessage, "from", Js.Json.string(currentUser));
      Js.Dict.set(keyExchangeMessage, "to", Js.Json.string(recipient));
      Js.Dict.set(keyExchangeMessage, "encryptedSharedKey", Js.Json.string(response["encryptedSharedKey"]));
      ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(keyExchangeMessage)));

      // Store the shared key locally
      let newSharedKeys = Js.Dict.fromArray(Js.Dict.entries(sharedKeys))
      Js.Dict.set(newSharedKeys, recipient, Bytes.to_string(response["sharedKey"]));
      setSharedKeys(_ => newSharedKeys);
      Promise.resolve()
    })
  }

  let getPublicKey = (username: string) => {
    switch socket {
    | Some(ws) =>
      let publicKeyRequest = Js.Dict.empty();
      Js.Dict.set(publicKeyRequest, "type", Js.Json.string("publicKeyRequest"));
      Js.Dict.set(publicKeyRequest, "from", Js.Json.string(currentUser));
      Js.Dict.set(publicKeyRequest, "to", Js.Json.string(username));
      ws->WebSocket.send(Js.Json.stringify(Js.Json.object_(publicKeyRequest)));

    | None => Js.log("WebSocket not connected")
    }
  }

  React.useEffect1(() => {
    switch socket {
    | None => {
        let ws = WebSocket.make("ws://localhost:8080")
        
        ws->WebSocket.onOpen(() => {
          Js.log("Connected to WebSocket")
          Js.log("Generating keypair")
          let (pubKey, privKey) = ChatEncryption.generate_keypair_for_new_user();
          Js.log("Public key generated")
          privKeyRef.current = privKey;
          // setPrivKey(_ => {
          //   Js.log("Private key generated and set")
          //   privKey
          // });
          Js.log(privKey)
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
                let sender = messageObj->Js.Dict.get("from")
                  ->Belt.Option.flatMap(Js.Json.decodeString)
                  ->Belt.Option.getWithDefault("Unknown")
                let sharedKey = Js.Dict.unsafeGet(sharedKeys, sender)
                let _ = ChatEncryption.decrypt_message(sharedKey, nonce, encryptedMessage)
                        -> Promise.then(decryptedMessage => {
                            Js.log("Message sender")
                            Js.log(messageObj->Js.Dict.get("from")
                              ->Belt.Option.flatMap(Js.Json.decodeString)
                              ->Belt.Option.getWithDefault("Unknown"))

                            setUnreadMessages(prevUnread => {
                              let newUnreadMessages = Js.Dict.fromArray(Js.Dict.entries(prevUnread));
                              let currentUnreadCount = switch Js.Dict.get(newUnreadMessages, sender) {
                              | Some(count) => count + 1
                              | None => 1
                              };
                              Js.Dict.set(newUnreadMessages, sender, currentUnreadCount);
                              newUnreadMessages;
                            });  

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
                            Promise.resolve()
                        })                
              }
            | Some("userList") => {                
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
                Js.log("Private Key Before Decrypting Message")
                Js.log(privKeyRef.current)
                let sharedKey = ChatEncryption.decrypt_recieved_shared_key(privKeyRef.current, encryptedSharedKey)
                Js.log("Decrypted shared key")
                Js.log(sharedKey)
                let newSharedKeys = Js.Dict.fromArray(Js.Dict.entries(sharedKeys))
                Js.Dict.set(newSharedKeys, from, Bytes.to_string(sharedKey))
                setSharedKeys(_ => newSharedKeys)
              }
            | Some("publicKeyRequestResponse") => {
              let theirPubKey = messageObj->Js.Dict.get("publicKeyInfo")
                ->Belt.Option.flatMap(Js.Json.decodeString)
                ->Belt.Option.getWithDefault("");
              let username = messageObj->Js.Dict.get("from")
                ->Belt.Option.flatMap(Js.Json.decodeString)
                ->Belt.Option.getWithDefault("Unknown");
              Js.log("Received public key");
              Js.log("From user: " ++ username);
              let _ = performKeyExchange(~recipient=username, ~theirPubKey, ws)
                      ->Promise.then(_ => {
                        Promise.resolve()
                        })
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
          Js.log("WebSocket connection closed xyz")
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
    let _ = ChatEncryption.encrypt_message(sharedKey, Bytes.of_string(message))
    -> Promise.then(response => {
      Js.Dict.set(messageData, "message", Js.Json.string(snd(response)))
      Js.Dict.set(messageData, "nonce", Js.Json.string(fst(response)))
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
      Promise.resolve()
    })
  }

  let handleUserSelect = user => {
    switch Js.Dict.get(sharedKeys, user) {
    | Some(_) => {
      // Reset unread messages for the selected user
      let newUnreadMessages = Js.Dict.fromArray(
        Js.Dict.entries(unreadMessages)
        ->Belt.Array.map(((key, value)) => (key, Belt.Int.toString(value)))
      );
      Js.Dict.unsafeDeleteKey(newUnreadMessages, user);
      setUnreadMessages(_ => 
        Js.Dict.fromArray(
          Js.Dict.entries(newUnreadMessages)
          ->Belt.Array.map(((key, value)) => (key, Belt.Int.fromString(value)->Belt.Option.getExn))
        )
      );
      setSelectedUser(_ => Some(user));
    }
    | None => {
        // Request the public key for the user
        switch socket {
        | Some(_ws) => 
        Js.log("Requesting public key for user: " ++ user)
        getPublicKey(user)
        setSelectedUser(_ => Some(user))
        | None => Js.log("WebSocket not connected")
        }
      }
    }

  }

  <div className="p-6 bg-gradient-to-r from-blue-200 to-slate-300 w-full h-full flex flex-col rounded-lg shadow-lg">
  <div className="flex h-full">
    <div className="w-1/4 pr-4 flex flex-col bg-white rounded-lg shadow-md">
      <h2 className="text-xl font-semibold text-gray-700 mb-4 px-4 py-2 bg-blue-100 rounded-t-lg border-b border-gray-200">
        {React.string("Available Users")}
      </h2>
      <ul className="flex-1 overflow-y-auto">
        {Belt.Array.length(availableUsers) > 0
          ? availableUsers->Belt.Array.mapWithIndex((idx, user) =>
            <li
              key={Belt.Int.toString(idx)}
              className={
                "flex items-center justify-between px-4 py-2 cursor-pointer hover:bg-blue-50 " ++
                (selectedUser == Some(user) ? "bg-blue-200 font-semibold" : "")
              }
              onClick={_ => handleUserSelect(user)}
            >
              <span className="truncate">{React.string(user)}</span>
              {switch Js.Dict.get(unreadMessages, user) {
              | Some(count) =>
                <span className="bg-red-500 text-white text-xs rounded-full w-6 h-6 flex items-center justify-center">
                  {React.string(Belt.Int.toString(count))}
                </span>
              | None => React.null
              }}
            </li>
          )->React.array
          : <li className="text-gray-500 text-center px-4 py-2">
              {React.string("No other users online")}
            </li>
        }
      </ul>
    </div>

   
    <div className="w-3/4 flex flex-col bg-white rounded-lg shadow-md">
      {switch selectedUser {
      | Some(user) =>
        <>
          <div className="text-xl font-semibold text-gray-700 px-4 py-2 bg-blue-100 rounded-t-lg border-b border-gray-200">
            {React.string("Chat with " ++ user)}
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            {switch messages {
            | [] =>
              <p className="text-gray-500 text-center mt-4">
                {React.string("No messages yet!")}
              </p>
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
                <div
                  key={Belt.Int.toString(idx)}
                  className={
                    "mb-4 p-3 rounded-lg " ++
                    (msg.from == currentUser ? "bg-blue-50 self-end text-right" : "bg-gray-100 self-start text-left")
                  }
                >
                  <div className="font-medium text-blue-600">
                    {React.string(msg.from ++ ":")}
                  </div>
                  <div className="text-gray-800">{React.string(msg.message)}</div>
                  <div className="text-xs text-gray-500 mt-1">{React.string(msg.timestamp)}</div>
                </div>
              )
              ->React.array
            }}
          </div>
          <div className="p-4 border-t border-gray-200">
            <ChatInput onSubmit={handleSendMessage} />
          </div>
        </>
      | None =>
        <div className="flex items-center justify-center flex-1">
          <div className="text-lg font-bold text-gray-500">
            {React.string("Pick a user to chat with")}
          </div>
        </div>
      }}
    </div>
  </div>
</div>
}