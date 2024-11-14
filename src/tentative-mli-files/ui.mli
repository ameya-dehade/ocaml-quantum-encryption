    (* 
    Fetch the list of users from the server or a predefined list.
    INPUT: 
        - unit: No input parameters.
    OUTPUT:
        - (string list, string) result: 
        - Ok(users): A list of usernames if the operation succeeds.
        - Error(msg): An error message if the operation fails.
    *)
    let fetch_users : unit -> (string list, string) result = fun () ->
    (* Placeholder: Fetch users *)
    Error "Not implemented"
    
    (* 
        Filter the user list based on a search query.
        INPUTS:
        - query: A string representing the search term entered by the user.
        - users: A list of strings representing the usernames to search within.
        OUTPUT:
        - string list: A filtered list of usernames that match the search query.
    *)
    let filter_users : string -> string list -> string list = fun query users ->
    (* Placeholder: Filter logic *)
    []
    
    (* 
        Handle user selection from the list to start a chat.
        INPUT:
        - username: A string representing the username of the selected user.
        OUTPUT:
        - unit: No output value, but it initiates the chat interface for the selected user.
    *)
    let on_user_select : string -> unit = fun username ->
    (* Placeholder: Navigate to chat with the selected user *)
    ()
    
    (* 
        Establish a secure connection for chatting by performing key exchange.
        INPUT:
        - username: A string representing the username of the user to establish a connection with.
        OUTPUT:
        - (unit, string) result:
            - Ok(): Indicates that the secure connection was successfully established.
            - Error(msg): An error message if the key exchange fails.
    *)
    let establish_secure_connection : string -> (unit, string) result = fun username ->
    (* Placeholder: Key exchange logic using Kyber *)
    Error "Not implemented"
    
    (* 
        Send a message to the selected user.
        INPUTS:
        - username: A string representing the recipient's username.
        - message: A string representing the plaintext message to be sent.
        OUTPUT:
        - (unit, string) result:
            - Ok(): Indicates that the message was successfully sent.
            - Error(msg): An error message if the sending fails.
    *)
    let send_message : string -> string -> (unit, string) result = fun username message ->
    (* Placeholder: Encrypt the message and send it to the user *)
    Error "Not implemented"
    
    (* 
        Receive a message from the selected user.
        INPUTS:
        - username: A string representing the sender's username.
        - encrypted_message: A string representing the encrypted message received.
        OUTPUT:
        - (string, string) result:
            - Ok(decrypted_message): The decrypted message as a plaintext string.
            - Error(msg): An error message if decryption fails.
    *)
    let receive_message : string -> string -> (string, string) result = fun username encrypted_message ->
    (* Placeholder: Decrypt the incoming message *)
    Error "Not implemented"
    
    (* 
        Load the chat history for the current session (temporary, non-persistent).
        INPUT:
        - username: A string representing the username of the user whose chat history is being fetched.
        OUTPUT:
        - (string list, string) result:
            - Ok(messages): A list of messages (as strings) for the current session.
            - Error(msg): An error message if the history cannot be fetched.
    *)
    let load_chat_session : string -> (string list, string) result = fun username ->
    (* Placeholder: Fetch temporary chat history *)
    Error "Not implemented"
    
    (* 
        Append a new message to the current session.
        INPUTS:
        - username: A string representing the username of the recipient.
        - message: A string representing the plaintext message to append.
        OUTPUT:
        - unit: No output value, but the message is added to the in-memory chat history.
    *)
    let append_to_chat_session : string -> string -> unit = fun username message ->
    (* Placeholder: Append the message to the chat history *)
    ()
    
    (* 
        Render the user list.
        INPUT:
        - users: A list of strings representing usernames to display.
        OUTPUT:
        - unit: No output value, but updates the UI to show the user list.
    *)
    let render_user_list : string list -> unit = fun users ->
    (* Placeholder: Render logic *)
    ()
    
    (* 
        Render the chat interface.
        INPUT:
        - username: A string representing the username of the recipient.
        OUTPUT:
        - unit: No output value, but updates the UI to display the chat interface for the selected user.
    *)
    let render_chat_interface : string -> unit = fun username ->
    (* Placeholder: Render chat UI for the selected user *)
    ()
    
    (* 
        Render incoming and outgoing messages.
        INPUTS:
        - username: A string representing the sender or recipient of the message.
        - message: A string representing the plaintext message to display.
        OUTPUT:
        - unit: No output value, but updates the UI to display the message in the chat interface.
    *)
    let render_message : string -> string -> unit = fun username message ->
    (* Placeholder: Render a single message in the chat interface *)
    ()


    (* 
    Start a secure chat session.
    INPUTS:
    - username: A string representing the name of the user to start a chat with.
    - publicKey: The public key of the user of type `publicKey`.
    OUTPUT:
    - Result<unit, string>:
        - Ok(): Indicates that the secure chat session was successfully established.
        - Error(msg): An error message if the session initiation fails.
    *)
    let startChatSession: (string, publicKey) => Result<unit, string>

    (* 
    End a secure chat session.
    INPUT:
    - username: A string representing the name of the user whose chat session is being terminated.
    OUTPUT:
    - unit: No output value, but the secure session is cleaned up (e.g., shared secret removed from memory).
    *)
    let endChatSession: string => unit


    (*Placeholder types for cryptographic entities*)
    type publicKey = string
    type privateKey = string
    type sharedKey = string
    type ciphertext = string

    (* Representation of the username-to-publicKey map*)
    type userPublicKeys = Js.Dict.t<publicKey>
    

    (* 
    Create a new user in the system.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the new user's name.
    OUTPUT:
    - Result<userPublicKeys, string>:
        - Ok(updatedMap): The updated map of usernames to public keys if the user is successfully created.
        - Error(msg): An error message if the username already exists or key generation fails.
    *)
    let createUser: (userPublicKeys, string) => Result<userPublicKeys, string>

    (* 
    Add a username-public key pair to the map.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the username to add.
    - publicKey: The public key to associate with the username.
    OUTPUT:
    - userPublicKeys: A new map with the username and public key added.
    *)
    let addUserKey: (userPublicKeys, string, publicKey) => userPublicKeys

    (* 
    Fetch the public key for a given username.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the username to look up.
    OUTPUT:
    - Result<publicKey, string>:
        - Ok(publicKey): The public key associated with the username if found.
        - Error(msg): An error message if the username is not found in the map.
    *)
    let fetchPublicKey: (userPublicKeys, string) => Result<publicKey, string>



    (* 
    Fetch the public key of a specific user.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the name of the user whose public key is being fetched.
    OUTPUT:
    - Result<publicKey, string>: 
        - Ok(publicKey): The public key of the user.
        - Error(msg): An error message if fetching the public key fails.
    *)
    let fetchUserPublicKey: (userPublicKeys, string) => Result<publicKey, string>

    (* 
    Remove a user from the map by their username.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the username to remove.
    OUTPUT:
    - userPublicKeys: A new map with the specified username removed.
    *)
    let removeUser: (userPublicKeys, string) => userPublicKeys

    (* 
    Check if a username exists in the map.
    INPUTS:
    - userKeys: The current map of type `userPublicKeys`.
    - username: A string representing the username to check.
    OUTPUT:
    - bool: True if the username exists in the map, false otherwise.
    *)
    let userExists: (userPublicKeys, string) => bool


    (* 
    Send a shared secret to a user.
    INPUTS:
    - publicKey: The recipient's public key of type `publicKey`.
    - sharedKey: The shared secret of type `sharedKey` to be sent.
    OUTPUT:
    - unit: No output value, but securely sends the shared secret.
    *)
    let sendSharedSecret: (publicKey, sharedKey) => unit

    (* 
    Receive a shared secret from a user.
    INPUTS:
    - ciphertext: The ciphertext encapsulating the shared secret.
    - privateKey: The recipient's private key of type `privateKey`.
    OUTPUT:
    - Result<sharedKey, string>:
        - Ok(sharedKey): The derived shared secret.
        - Error(msg): An error message if decryption fails.
    *)
    let receiveSharedSecret: (ciphertext, privateKey) => Result<sharedKey, string>

    (* 
    Send an encrypted message.
    INPUTS:
    - message: A string representing the plaintext message to be sent.
    - sharedKey: The shared key of type `sharedKey` for encryption.
    OUTPUT:
    - unit: No output value, but securely sends the encrypted message.
    *)
    let sendMessage: (string, sharedKey) => unit

    (* 
    Receive and decrypt a message.
    INPUTS:
    - ciphertext: The ciphertext of the encrypted message.
    - sharedKey: The shared key of type `sharedKey` used for decryption.
    OUTPUT:
    - Result<string, string>:
        - Ok(message): The decrypted plaintext message.
        - Error(msg): An error message if decryption fails.
    *)
    let receiveMessage: (ciphertext, sharedKey) => Result<string, string>






