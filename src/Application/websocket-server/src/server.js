const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

// Store all connected clients with their usernames and public keys
const clients = new Map();
const publicKeys = new Map();

wss.on('connection', (ws) => {
  ws.on('message', (rawMessage) => {
    try {
      const messageData = JSON.parse(rawMessage);
      
      // Handle different types of messages
      switch (messageData.type) {
        case 'login': {
          // Store the client with their username
          ws.username = messageData.username;
          clients.set(ws, messageData.username);
          
          // Store public key 
          console.log("RECEIVED login pub key FOR", messageData.username)
          publicKeys.set(messageData.username, messageData.pubKey);
          
          // Broadcast the updated user list to all clients
          broadcastUserList();
          break;
        }
        case 'privateChat': {
          // Send private message to specific user
          clients.forEach((username, client) => {
            if (username === messageData.to && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'privateChat',
                from: messageData.from,
                to: messageData.to,
                message: messageData.message,
                nonce: messageData.nonce,
                timestamp: messageData.timestamp
              }));
              console.log("Sent private message to :", messageData.to);
            }
          });
          break;
        }
        case 'keyExchange': {
          // Forward the key exchange response to the recipient
          clients.forEach((username, client) => {
            if (username === messageData.to && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'keyExchange',
                from: messageData.from,
                encryptedSharedKey: messageData.encryptedSharedKey
              }));
              console.log("Sent key request message to :", messageData.to);
            }
          });
          break;
        }
        case 'publicKeyRequest': {
          // Send public key info to the client
          clients.forEach((username, client) => {
            if (username === messageData.from && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'publicKeyRequestResponse',
                from: messageData.to,
                publicKeyInfo: publicKeys.get(messageData.to)
              }));
              console.log("Sending public key info to : ", messageData.from);
            }
          });
          break;
        }
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });

  ws.on('close', () => {
    // Remove client from the map when they disconnect
    const username = clients.get(ws);
    clients.delete(ws);

    publicKeys.delete(username);
    
    // Broadcast updated user list
    broadcastUserList();
    console.log('Client disconnected');
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    clients.delete(ws);
  });
});

// Function to broadcast the current list of users
function broadcastUserList() {
  const userList = Array.from(clients.values());
  
  clients.forEach((username, client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({
        type: 'userList',
        users: userList
      }));
    }
  });
}

console.log('WebSocket server started on port 8080');
