// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as JsxRuntime from "react/jsx-runtime";

function ChatInput(props) {
  var onSubmit = props.onSubmit;
  var match = React.useState(function () {
        return "";
      });
  var setText = match[1];
  var text = match[0];
  var handleInputChange = function ($$event) {
    var value = $$event.currentTarget.value;
    setText(function (_prev) {
          return value;
        });
  };
  var handleSendClick = function (param) {
    if (text !== "") {
      onSubmit(text);
      return setText(function (_prev) {
                  return "";
                });
    }
    
  };
  var handleKeyDown = function ($$event) {
    if ($$event.key === "Enter" && text !== "") {
      $$event.preventDefault();
      onSubmit(text);
      return setText(function (_prev) {
                  return "";
                });
    }
    
  };
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx("input", {
                      className: "input input-bordered flex-1 mr-2",
                      placeholder: "Type a message",
                      type: "text",
                      value: text,
                      onKeyDown: handleKeyDown,
                      onChange: handleInputChange
                    }),
                JsxRuntime.jsx("button", {
                      children: "Send",
                      className: "btn btn-primary",
                      onClick: handleSendClick
                    })
              ],
              className: "flex items-center"
            });
}

var make = ChatInput;

export {
  make ,
}
/* react Not a pure module */
