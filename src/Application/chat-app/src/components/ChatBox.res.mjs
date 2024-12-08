// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Bytes from "rescript/lib/es6/bytes.js";
import * as React from "react";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Js_json from "rescript/lib/es6/js_json.js";
import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as ChatInput from "./ChatInput.res.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Encryption from "../bindings/Encryption.res.mjs";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Belt_Result from "rescript/lib/es6/belt_Result.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Belt_SetString from "rescript/lib/es6/belt_SetString.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";

function ChatBox(props) {
  var currentUser = props.currentUser;
  var match = React.useState(function () {
        return [];
      });
  var setMessages = match[1];
  var messages = match[0];
  var match$1 = React.useState(function () {
        
      });
  var setSocket = match$1[1];
  var socket = match$1[0];
  var match$2 = React.useState(function () {
        return [];
      });
  var setAvailableUsers = match$2[1];
  var availableUsers = match$2[0];
  var match$3 = React.useState(function () {
        
      });
  var setSelectedUser = match$3[1];
  var selectedUser = match$3[0];
  React.useState(function () {
        return {};
      });
  Encryption.randomnessSetup();
  var match$4 = Encryption.generateKeypair();
  var match$5 = Encryption.generateAndEncryptSharedKey(match$4[0]);
  var sharedKey = match$5[0];
  React.useEffect((function () {
          if (socket === undefined) {
            var ws = new WebSocket("ws://localhost:8080");
            ws.onopen = (function () {
                console.log("Connected to WebSocket");
                var loginData = {};
                loginData["type"] = "login";
                loginData["username"] = currentUser;
                ws.send(JSON.stringify(loginData));
                setSocket(function (param) {
                      return Caml_option.some(ws);
                    });
              });
            ws.onmessage = (function ($$event) {
                try {
                  var message = JSON.parse($$event.data);
                  var messageObj = Belt_Option.getExn(Js_json.decodeObject(message));
                  var messageType = Belt_Option.flatMap(Js_dict.get(messageObj, "type"), Js_json.decodeString);
                  var exit = 0;
                  if (messageType === undefined) {
                    return ;
                  }
                  switch (messageType) {
                    case "chat" :
                    case "privateChat" :
                        exit = 1;
                        break;
                    case "userList" :
                        console.log("Received user list");
                        var obj = Js_json.decodeObject(message);
                        var users;
                        if (obj !== undefined) {
                          var usersJson = Js_dict.get(obj, "users");
                          if (usersJson !== undefined) {
                            var arr = Js_json.decodeArray(usersJson);
                            users = arr !== undefined ? Belt_SetString.toArray(Belt_SetString.remove(Belt_SetString.fromArray(Belt_Array.keepMap(arr, Js_json.decodeString)), currentUser)) : [];
                          } else {
                            users = [];
                          }
                        } else {
                          users = [];
                        }
                        console.log("Parsed users:");
                        console.log(users);
                        return setAvailableUsers(function (param) {
                                    return users;
                                  });
                    default:
                      return ;
                  }
                  if (exit === 1) {
                    var encryptedMessage = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "message"), Js_json.decodeString), "");
                    var nonce = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "nonce"), Js_json.decodeString), "");
                    var decryptedMessage = Encryption.decryptMessage(sharedKey, nonce, encryptedMessage);
                    var newMessage_type_ = Caml_obj.equal(messageType, "privateChat") ? "PrivateChat" : "Chat";
                    var newMessage_from = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "from"), Js_json.decodeString), "Unknown");
                    var newMessage_to_ = Belt_Option.flatMap(Js_dict.get(messageObj, "to"), Js_json.decodeString);
                    var newMessage_message = Belt_Result.getWithDefault(Belt_Result.map(decryptedMessage, Bytes.to_string), "");
                    var newMessage_timestamp = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "timestamp"), Js_json.decodeString), "");
                    var newMessage = {
                      type_: newMessage_type_,
                      from: newMessage_from,
                      to_: newMessage_to_,
                      message: newMessage_message,
                      timestamp: newMessage_timestamp
                    };
                    return setMessages(function (prev) {
                                if (Belt_Array.some(prev, (function (existingMsg) {
                                          return existingMsg.from === newMessage_from && existingMsg.message === newMessage_message ? existingMsg.timestamp === newMessage_timestamp : false;
                                        })) || !(newMessage_type_ === "Chat" || newMessage_type_ === "PrivateChat" && (newMessage_from === currentUser || Caml_obj.equal(newMessage_to_, currentUser)))) {
                                  return prev;
                                } else {
                                  return Belt_Array.concat(prev, [newMessage]);
                                }
                              });
                  }
                  
                }
                catch (raw_err){
                  var err = Caml_js_exceptions.internalToOCamlException(raw_err);
                  console.log("Error parsing message");
                  console.log(err);
                  return ;
                }
              });
            ws.onclose = (function () {
                console.log("WebSocket connection closed");
                setSocket(function (param) {
                      
                    });
              });
          }
          return (function () {
                    if (socket !== undefined) {
                      Caml_option.valFromOption(socket).onclose = (function () {
                          
                        });
                      return setSocket(function (param) {
                                  
                                });
                    }
                    
                  });
        }), []);
  var handleSendMessage = function (message) {
    var timestamp = new Date().toISOString();
    var messageData = {};
    if (selectedUser !== undefined) {
      messageData["type"] = "privateChat";
      messageData["to"] = selectedUser;
    } else {
      console.log("No user selected");
    }
    messageData["from"] = currentUser;
    messageData["timestamp"] = timestamp;
    var match = Encryption.encryptMessage(sharedKey, Bytes.of_string(message));
    messageData["message"] = match[1];
    messageData["nonce"] = match[0];
    if (socket !== undefined) {
      Caml_option.valFromOption(socket).send(JSON.stringify(messageData));
      return setMessages(function (prev) {
                  var newMessage_type_ = selectedUser !== undefined ? "PrivateChat" : "Chat";
                  var newMessage = {
                    type_: newMessage_type_,
                    from: currentUser,
                    to_: selectedUser,
                    message: message,
                    timestamp: timestamp
                  };
                  return Belt_Array.concat(prev, [newMessage]);
                });
    }
    
  };
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsxs("div", {
                    children: [
                      JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("h2", {
                                    children: "Available Users",
                                    className: "text-lg font-bold mb-4"
                                  }),
                              JsxRuntime.jsx("ul", {
                                    children: availableUsers.length !== 0 ? Belt_Array.mapWithIndex(availableUsers, (function (idx, user) {
                                              return JsxRuntime.jsx("li", {
                                                          children: user,
                                                          className: "p-2 hover:bg-gray-100 cursor-pointer " + (
                                                            Caml_obj.equal(selectedUser, user) ? "bg-blue-100" : ""
                                                          ),
                                                          onClick: (function (param) {
                                                              setSelectedUser(function (param) {
                                                                    return user;
                                                                  });
                                                            })
                                                        }, String(idx));
                                            })) : JsxRuntime.jsx("li", {
                                            children: "No other users online",
                                            className: "text-gray-500 text-center"
                                          }),
                                    className: "bg-white rounded-lg p-2"
                                  })
                            ],
                            className: "w-1/4 pr-4"
                          }),
                      JsxRuntime.jsx("div", {
                            children: selectedUser !== undefined ? JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                    children: [
                                      JsxRuntime.jsx("div", {
                                            children: "Chat with " + selectedUser,
                                            className: "text-lg font-bold mb-2"
                                          }),
                                      JsxRuntime.jsx("div", {
                                            children: messages.length !== 0 ? Belt_Array.mapWithIndex(Belt_Array.keepMap(messages, (function (msg) {
                                                          var match = msg.type_;
                                                          if (selectedUser !== undefined && match === "PrivateChat" && (msg.from === selectedUser && Caml_obj.equal(msg.to_, currentUser) || msg.from === currentUser && Caml_obj.equal(msg.to_, selectedUser))) {
                                                            return msg;
                                                          }
                                                          
                                                        })), (function (idx, msg) {
                                                      return JsxRuntime.jsxs("div", {
                                                                  children: [
                                                                    JsxRuntime.jsxs("div", {
                                                                          children: [
                                                                            JsxRuntime.jsx("span", {
                                                                                  children: msg.from + ": ",
                                                                                  className: "font-bold"
                                                                                }),
                                                                            JsxRuntime.jsx("span", {
                                                                                  children: msg.message
                                                                                })
                                                                          ]
                                                                        }),
                                                                    JsxRuntime.jsx("div", {
                                                                          children: msg.timestamp,
                                                                          className: "text-xs text-gray-500"
                                                                        })
                                                                  ],
                                                                  className: "mb-2"
                                                                }, String(idx));
                                                    })) : JsxRuntime.jsx("p", {
                                                    children: "No messages yet!",
                                                    className: "text-gray-500 text-center"
                                                  }),
                                            className: "flex-1 overflow-y-scroll mb-4 bg-white rounded-lg p-2"
                                          }),
                                      JsxRuntime.jsx(ChatInput.make, {
                                            onSubmit: handleSendMessage
                                          })
                                    ]
                                  }) : JsxRuntime.jsx("div", {
                                    children: "Pick a user to chat with",
                                    className: "text-lg font-bold mb-2 text-center"
                                  }),
                            className: "w-3/4 flex flex-col"
                          })
                    ],
                    className: "flex"
                  }),
              className: "p-4 bg-slate-200 w-full h-full flex flex-col rounded-lg"
            });
}

var make = ChatBox;

export {
  make ,
}
/* react Not a pure module */
