@react.component
let make = (~onSubmit: string => unit) => {
  let (text, setText) = React.useState(() => "")

  let handleInputChange = (event) => {
    let value = ReactEvent.Form.currentTarget(event)["value"]
    setText(_prev => value)
  }

  let handleSendClick = (_) => {
    if (text !== "") {
      onSubmit(text)
      setText(_prev => "")
    }
  }

  let handleKeyDown = (event) => {
    if (ReactEvent.Keyboard.key(event) === "Enter" && text !== "") {
      ReactEvent.Keyboard.preventDefault(event)
      onSubmit(text)
      setText(_prev => "")
    }
  }

  <div className="flex items-center bg-gray-100 p-4 rounded-lg shadow-md">
    <input
      type_="text"
      placeholder="Type a message..."
      value={text}
      onChange={handleInputChange}
      onKeyDown={handleKeyDown}
      className="flex-1 px-4 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 outline-none text-gray-700"
    />
    <button
      className={`ml-3 px-4 py-2 rounded-md text-white font-medium ${
        text === ""
          ? "bg-gray-400 cursor-not-allowed"
          : "bg-blue-500 hover:bg-blue-600"
      }`}
      onClick={handleSendClick}
      disabled={text === ""}
    >
      {React.string("Send")}
    </button>
  </div>
}
