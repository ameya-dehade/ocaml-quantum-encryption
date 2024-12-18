# ocaml-quantum-encryption
Quantum Encryption Chat Application for Functional Programming Final Project.

Implementation of a Rescript Chat App that uses the Kyber Algorithm for key exchange, and uses AES-GCM for subsequent message encryption. This repository has two parts in the src folder:

1. **Encryption library** <br>
   a. Kyber.ml - Contains all the logic for the Kyber's Key Generation, Encryption and Decryption, along with implementations for the Polynomial and Polynomial Matrices that are used.<br>
   b. Chat_encryption.ml - Abstracts away the Kyber algorithm into an interface that can be used by the chat application without caring about the underlying key exchange algorithm or message encryption algorithm
2. **Application** <br>
   a. App.res - Entry point of chat application, manages application's main state (username) and controls navigation between login and chat interface<br>
   b. Login.res - Handles login UI and functionality. Accepts username from user and submits to main application state to initiate chat<br>
   c. ChatBox.res - Core chat interface. Displays list of online users, handles user selection, and manages sending and receiving encrypted messages via WebSockets<br>
   d. ChatInput.res - Reusable component for typing and sending messages<br>
   e. MessageType.res - Defines the types and structures for various message formats exchanged in the app<br>
   f. WebSocket.res - Manages WebSocket connections handling events like onMessage, onOpen, and onClose<br>
   g. server.js - WebSocket server that facilitates communication between clients. Manages connected users, handles private messaging, broadcasts the user list, and manages the public key distribution for encryption

## Applicaton
### Instructions to run (Application folder)
1. Navigate to the chat-app directory and run "npm install"<br>
2. Navigate to the websocket-server directory and run "npm install"<br>
3. In one terminal window navigate to the chat-app directory and run "npm run res:dev"<br>
4. In a seperate terminal window naviage to the chat-app directory and run "npm run dev"<br>
5. In a seperate terminal window navigate to the src folder inside websocket-server and run "node server.js"<br>
6. Open your browser and go to the local host link and log in and start chatting. 
### Features
   a. Log in page<br>
   b. Dynamic user list<br>
   c. Encrypted Private messaging<br>
   d. Message notification and counter of unseen messages per user<br>
   e. User-Friendly Interface

## Algorithm
### Overview of Kyber
1. **Lattice Construction and Polynomial Rings**: Kyber operates over polynomial rings modulo a prime q, leveraging structured lattices. Keys and messages are represented as elements in these rings, and operations (e.g., addition, multiplication) are performed modulo q and x^n+1, where n is a power of 2.
2. **Key Generation and Noise**: Security relies on the Learning With Errors (LWE) problem. During key generation, small random "noise" is added to polynomials to create public/private key pairs. The noise ensures that recovering the secret key from the public key remains computationally hard, even for quantum adversaries.
3. **Encryption and Decryption**: Encryption involves encoding the plaintext into a polynomial, performing polynomial multiplications with the public key, and adding noise for security. Decryption uses the private key to undo these operations and recover the plaintext while correcting for the introduced noise.
4. References - <a>https://cryptopedia.dev/posts/kyber/</a>, <a>https://en.wikipedia.org/wiki/Kyber</a>, <a>https://pq-crystals.org/kyber/</a>

### Testing
1. Extensive test suite that checks all functions in the supporting Polynomial and Polynomial Matrix library, along with the Kyber and Chat Encryption logic.
2. ```Test Coverage: 243/258 (94.19%)```

### Instructions to build and test
1. Build project - dune build
2. Test project - dune test

## Usage in Chat App - Painful!
Since there was no way to directly use this OCaml library in the Rescript Application, we had to use the command:<br>
```cat myfile.ml | npx rescript format -stdin .ml > myfile.res```<br>
to convert the .ml to .res.<br>
HOWEVER, many libraries we used (like Core and CryptoKit) had no Rescript support, so we had to replace them with alternatives that had very different usage/function signatures. This meant that we had rework a significant chunk of the converted .res files to use appropriate libraries. Chat_encryption.res had to be written completely from scratch.

