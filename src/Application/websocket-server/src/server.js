const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

// Store all connected clients with their usernames
const clients = new Map();

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
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });

  ws.on('close', () => {
    // Remove client from the map when they disconnect
    clients.delete(ws);
    
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