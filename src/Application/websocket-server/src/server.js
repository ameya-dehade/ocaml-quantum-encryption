const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

// Store all connected clients with their usernames and public keys
const clients = new Map();
const userPublicKeys = new Map(); // Map to store usernames and their public keys

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
          
          // Store the public key associated with the username
          if (messageData.pubKey) {
            userPublicKeys.set(messageData.username, messageData.pubKey);
          }
          
          // Broadcast the updated user list to all clients
          broadcastUserList();
          break;
        }
        case 'chat': {
          // Broadcast the chat message to all connected clients
          clients.forEach((username, client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'chat',
                from: messageData.from,
                message: messageData.message,
                timestamp: messageData.timestamp
              }));
            }
          });
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
                timestamp: messageData.timestamp
              }));
            }
            // Also send back to sender for display in their chat window
            if (username === messageData.from && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'privateChat',
                from: messageData.from,
                to: messageData.to,
                message: messageData.message,
                timestamp: messageData.timestamp
              }));
            }
          });
          break;
        }
        case 'keyExchange': {
          // Handle key exchange initiation
          const recipient = messageData.to;
          const recipientPublicKey = userPublicKeys.get(recipient);

          if (recipientPublicKey) {
            // Send the recipient's public key back to the initiator
            ws.send(JSON.stringify({
              type: 'keyExchangeResponse',
              to: messageData.from,
              from: recipient,
              pubKey: recipientPublicKey
            }));
          } else {
            ws.send(JSON.stringify({
              type: 'error',
              message: `Public key for user ${recipient} not found`
            }));
          }
          break;
        }
        case 'keyExchangeResponse': {
          // Forward the key exchange response to the recipient
          clients.forEach((username, client) => {
            if (username === messageData.to && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({
                type: 'keyExchangeResponse',
                from: messageData.from,
                pubKey: messageData.pubKey
              }));
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
    userPublicKeys.delete(username); // Clean up public key storage
    
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
