// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Login from "./components/Login.res.mjs";
import * as React from "react";
import * as ChatBox from "./components/ChatBox.res.mjs";
import * as JsxRuntime from "react/jsx-runtime";

function App(props) {
  var match = React.useState(function () {
        return "";
      });
  var setUsername = match[1];
  var username = match[0];
  var handleUsernameSubmit = function (name) {
    setUsername(function (_prev) {
          return name;
        });
  };
  var tmp = username === "" ? JsxRuntime.jsx(Login.make, {
          onSubmit: handleUsernameSubmit
        }) : JsxRuntime.jsx(ChatBox.make, {
          currentUser: username
        });
  return JsxRuntime.jsx("div", {
              children: tmp,
              className: "container mx-auto h-screen flex flex-col justify-center items-center"
            });
}

var make = App;

export {
  make ,
}
/* Login Not a pure module */
