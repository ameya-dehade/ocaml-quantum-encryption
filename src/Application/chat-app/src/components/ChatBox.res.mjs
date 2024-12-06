// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Js_json from "rescript/lib/es6/js_json.js";
import * as ChatInput from "./ChatInput.res.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Belt_SetString from "rescript/lib/es6/belt_SetString.js";
import * as JsxRuntime from "react/jsx-runtime";

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
                  if (messageType === undefined) {
                    return ;
                  }
                  switch (messageType) {
                    case "chat" :
                        var newMessage_from = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "from"), Js_json.decodeString), "Unknown");
                        var newMessage_message = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "message"), Js_json.decodeString), "");
                        var newMessage_timestamp = Belt_Option.getWithDefault(Belt_Option.flatMap(Js_dict.get(messageObj, "timestamp"), Js_json.decodeString), new Date().toISOString());
                        var newMessage = {
                          type_: "Chat",
                          from: newMessage_from,
                          message: newMessage_message,
                          timestamp: newMessage_timestamp
                        };
                        return setMessages(function (prev) {
                                    if (Belt_Array.some(prev, (function (existingMsg) {
                                              return existingMsg.from === newMessage_from && existingMsg.message === newMessage_message ? existingMsg.timestamp === newMessage_timestamp : false;
                                            }))) {
                                      return prev;
                                    } else {
                                      return Belt_Array.concat(prev, [newMessage]);
                                    }
                                  });
                    case "userList" :
                        var users = Belt_SetString.toArray(Belt_SetString.remove(Belt_SetString.fromArray(Belt_Option.getWithDefault(Belt_Option.map(Belt_Option.flatMap(Js_dict.get(messageObj, "users"), Js_json.decodeArray), (function (arr) {
                                                return Belt_Array.keepMap(arr, Js_json.decodeString);
                                              })), [])), currentUser));
                        return setAvailableUsers(function (param) {
                                    return users;
                                  });
                    default:
                      return ;
                  }
                }
                catch (exn){
                  console.log("Error parsing message");
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
    messageData["type"] = "chat";
    messageData["from"] = currentUser;
    messageData["message"] = message;
    messageData["timestamp"] = timestamp;
    if (socket !== undefined) {
      Caml_option.valFromOption(socket).send(JSON.stringify(messageData));
      return ;
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
                                                          className: "p-2 hover:bg-gray-100 cursor-pointer"
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
                      JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("div", {
                                    children: messages.length !== 0 ? Belt_Array.mapWithIndex(messages, (function (idx, msg) {
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
                            ],
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
